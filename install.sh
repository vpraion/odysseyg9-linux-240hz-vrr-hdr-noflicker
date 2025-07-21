#!/bin/bash

$MKINIT_CONF=/etc/mkinitcpio.conf
$GRUB_CONF=/etc/default/grub

# Check for grub-mkconfig
if ! command -v grub-mkconfig &> /dev/null; then
    echo "❌ grub-mkconfig not found in \$PATH. Install wizard aborted."
    exit 2
else
    echo "✅ grub-mkconfig found! Proceeding..."
fi

# Check for sshd
if ! command -v sshd &> /dev/null; then
    echo "❌ sshd not found. 🔐 SSH access is recommended in case something goes wrong."
    read -rp "Would you like to install it and relaunch the install wizard afterwards? (y/n) " SSHD_WANTED
    if [[ "$SSHD_WANTED" == "y" ]]; then
        echo "👉 Please install sshd according to your distribution and relaunch the install wizard afterwards."
        exit 0
    else
        echo "⚠️ Without SSH, you'll need to chroot with an installer medium if something goes wrong."
    fi
else
    if ! systemctl is-active --quiet sshd; then
        read -rp "🔐 sshd is installed but not running. Enable SSH for remote access? (y/n) " ENABLE_SSHD
        if [[ "$ENABLE_SSHD" == "y" ]]; then
            echo "⚙️ Enabling sshd service..."
            sudo systemctl enable --now sshd
            if [[ $? -ne 0 ]]; then
                echo "❌ Failed to enable sshd. Exiting..."
                exit 1
            fi
            echo "🔑 SSH is now enabled. You can connect remotely via SSH."
            echo "🔒 Please ensure you have set a password or SSH key for secure access."

            if ! command -v ip &> /dev/null; then
                echo "ℹ️ Please find your local IP address manually and note it."
            else
                echo "🌐 Connect on your local network using: ssh username@IP"
                ip -4 addr show | grep inet | awk '{print $2}' | cut -d/ -f1 | grep '192' || echo "⚠️ No typical local 192.x.x.x IP found."
            fi
        fi
    fi
fi

# Detect DisplayPort outputs with EDID
DP_PORTS=()
for i in $(ls /sys/class/drm | grep 'DP'); do
    # Check if the EDID file contains any non-null bytes by removing null characters (\0)
    # and testing if the result is non-empty, indicating valid EDID data is present.
    if [[ -n $(tr -d '\0' < "/sys/class/drm/$i/edid") ]]; then
        echo "🔍 EDID found in /sys/class/drm/$i"
        DP_PORTS+=($(echo "$i" | grep -o 'DP.*'))
    fi
done

if [[ ${#DP_PORTS[@]} -eq 0 ]]; then
    echo "❌ No DisplayPort outputs with EDID found."
    exit 1
fi

# Prompt user to select DP output
echo "🎯 Select a DisplayPort output:"
PS3="Please enter your choice number: "

select DP_PORT in "${DP_PORTS[@]}"; do
    if [[ -n "$DP_PORT" ]]; then
        echo "✅ You chose: $DP_PORT"
        break
    else
        echo "❌ Invalid choice. Try again."
    fi
done

echo "🖥️ Select the EDID corresponding to your monitor :"

select EDID in "$(ls edids)"; do
    if [[ -n "$EDID" ]]; then
        $EDID=$EDID
        echo "✅ You chose: $EDID"
        break
    else
        echo "❌ Invalid choice. Try again."
    fi
done


mkdir -p backup
mkdir -p tmp
cp $MKINIT_CONF backup/mkinitcpio.conf
cp $MKINIT_CONF tmp/mkinitcpio.conf
cp $GRUB_CONF backup/grub
cp $GRUB_CONF tmp/grub

sudo cp edids/$EDID /usr/lib/firmware/edid/$EDID

if grep -q "$EDID" tmp/mkinitcpio.conf; then
    echo "✅ EDID file already listed in tmp/mkinitcpio.conf, replacing with updated path if needed..."
    sudo sed -i "s|/usr/lib/firmware/edid/[^ ]*|$EDID|" tmp/mkinitcpio.conf
else
    echo "➕ EDID file not listed, appending it to FILES=()"
    sudo sed -i "/^FILES=(/a \ \ \ \ $EDID" tmp/mkinitcpio.conf
fi

# sudo mkinitcpio -P

$EDID_PARAM="drm.edid_firmware=$DP_PORT:edid/$EDID"

if grep -q "drm.edid_firmware=" tmp/grub; then
    echo "✅ EDID parameter already present in GRUB config, updating..."
    sudo sed -i "s|drm\.edid_firmware=[^ ]*|$EDID_PARAM|" tmp/grub
else
    echo "➕ Adding EDID parameter to GRUB_CMDLINE_LINUX_DEFAULT..."
    sudo sed -i "/^GRUB_CMDLINE_LINUX_DEFAULT=/s/\"/ $EDID_PARAM\"/" tmp/grub
fi

# sudo grub-mkconfig -o /boot/grub/grub.cfg