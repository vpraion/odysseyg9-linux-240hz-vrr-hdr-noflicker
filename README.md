# Samsung Odyssey G9 on Linux - 240Hz, VRR & HDR Without Flicker or Ghosting

## Tested on Arch Linux with KDE, but should work on other distros as well.

### Why this guide?
This guide complements the work found [here](https://gitlab.freedesktop.org/drm/amd/-/issues/1442#note_1017689), which managed to enable 240Hz at the cost of losing Variable Refresh Rate (VRR). You might have either followed that guide and lost VRR, or your monitor keeps turning on and off with artifacts all over the place when trying to use 240Hz.

This guide is specifically for the **LC49G95** model (5120x1440 - 240Hz - VA - FreeSync Premium - FreeSync range 60-240Hz - HDR).

It seems that many of the users affected by this issue were using an *AMD RX 6XXX series*, which is my case (**6900 XT**). I think the solution that I provide works whichever GPU you have, but be cautious.

---

## Disclaimer

**Important:** Before proceeding with this guide, it's highly recommended to set up SSH access to your machine in case something goes wrong during the reboot, particularly with display settings. If you end up with a black screen or incorrect display settings (e.g., if your monitor is different from the one used in this guide), you may need to remove the EDID configuration from both initramfs and the kernel parameters.

### Steps to Undo the Changes if Display Breaks and assuming that you've already set 240hz refresh rate on the Monitor System itself

1. **Access the system via SSH**:
   - If SSH is already enabled, connect from another machine using:
     ```bash
     ssh user@your-linux-machine-ip
     ```

2. **Remove the EDID file from initramfs**:
   - Delete the EDID file reference in the initramfs configuration:
     ```bash
     sudo nano /etc/mkinitcpio.conf
     ```
   - Remove the parameters you added in the `FILES` array:
     ```bash
     FILES=()
     ```

   - Regenerate the initramfs:
     ```bash
     sudo mkinitcpio -P
     ```

3. **Remove the EDID from the kernel parameters**:
   - Edit the GRUB configuration to remove the EDID kernel parameter:
     ```bash
     sudo nano /etc/default/grub
     ```
   - Delete the `drm.edid_firmware=DP-1:edid/g9.bin` parameter from the `GRUB_CMDLINE_LINUX_DEFAULT` line.

   - Regenerate the bootloader configuration:
     ```bash
     sudo grub-mkconfig -o /boot/grub/grub.cfg
     ```

4. **Reboot**:
   - Reboot the system to apply the changes:
     ```bash
     sudo reboot
     ```

This should restore your system's display settings to their default state.

## Steps

### 1. Adding the EDID file to initramfs
First, copy the provided EDID file to the firmware directory:
```bash
sudo cp g9.bin /usr/lib/firmware/edid/g9.bin
```

Edit the initramfs configuration file:
```bash
sudo nano /etc/mkinitcpio.conf
```
Add the EDID path to the `FILES` array:
```bash
FILES=(/usr/lib/firmware/edid/g9.bin)
```

Regenerate the initramfs:
```bash
sudo mkinitcpio -P
```

### 2. Adding the EDID to Linux kernel parameters
Edit the GRUB configuration file:
```bash
sudo nano /etc/default/grub
```

Add the following parameter to `GRUB_CMDLINE_LINUX_DEFAULT`:
```bash
drm.edid_firmware=DP-1:edid/g9.bin
```
**(Ensure `DP-1` is your actual DisplayPort connector; this requires a DisplayPort connection)**

Example:
```bash
GRUB_CMDLINE_LINUX_DEFAULT="... drm.edid_firmware=DP-1:edid/g9.bin"
```

Regenerate the bootloader configuration:
```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

---

## 3. Updating the Monitor Firmware
If your firmware is outdated, you need a **USB drive (mine was formatted as VFAT)**.

- Download the latest firmware from the official Samsung support page:  
  [Samsung LC49G95 Firmware](https://www.samsung.com/fr/support/model/LC49G95TSSUXEN/#downloads)
- Unzip the downloaded file.
- Copy the firmware file from the extracted archive **without renaming it** to your USB drive.
- Insert the USB drive into the **correct** USB port on the monitor (50% chance to get it right!).
- Use the **OSD menu** on your monitor to start the firmware upgrade process.
- You can now avoid flickering and ghosting by enabling VRR Control, located in the "System Panel" of your OSD.

---

## Background Story
I spent over **15 hours** troubleshooting this issue through trial and error.
For some unknown reason, everything works fine on **Windows**, but not on **Linux**.
The EDID reported by my monitor differs between Windows and Linux.

After discovering the [GitLab issue](https://gitlab.freedesktop.org/drm/amd/-/issues/1442#note_1017689), I found an **EDID file that partially worked**, but VRR was still disabled. Through further **manual testing**, I figured out which values needed modification to restore VRR.

Most GUI tools for editing EDID files **failed**, as the G9’s EDID format appears to be unconventional.

Now, everything is working as expected—**240Hz, VRR, and HDR enabled without flickering or ghosting!** 🚀
