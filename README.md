# Samsung Odyssey G9 on Linux - 240Hz, VRR & HDR Without Flicker or Ghosting

## Tested on Arch Linux with KDE, but should work on other distros as well.

### Why this guide?
This guide complements the work found [here](https://gitlab.freedesktop.org/drm/amd/-/issues/1442#note_1017689), which managed to enable 240Hz at the cost of losing Variable Refresh Rate (VRR). You might have either followed that guide and lost VRR, or your monitor keeps turning on and off with artifacts all over the place when trying to use 240Hz.

This guide is specifically for the **LC49G95** model (5120x1440 - 240Hz - VA - FreeSync Premium - FreeSync range 60-240Hz - HDR).

---

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
If your firmware is outdated, you need a **USB drive (formatted as VFAT)**.

- Download the latest firmware from the official Samsung support page:  
  [Samsung LC49G95 Firmware](https://www.samsung.com/fr/support/model/LC49G95TSSUXEN/#downloads)
- Unzip the downloaded file.
- Copy the firmware file from the extracted archive **without renaming it** to your USB drive.
- Insert the USB drive into the **correct** USB port on the monitor (50% chance to get it right!).
- Use the **OSD menu** on your monitor to start the firmware upgrade process.

---

## Background Story
I spent over **15 hours** troubleshooting this issue through trial and error.
For some unknown reason, everything works fine on **Windows**, but not on **Linux**.
The EDID reported by my monitor differs between Windows and Linux.

After discovering the [GitLab issue](https://gitlab.freedesktop.org/drm/amd/-/issues/1442#note_1017689), I found an **EDID file that partially worked**, but VRR was still disabled. Through further **manual testing**, I figured out which values needed modification to restore VRR.

Most GUI tools for editing EDID files **failed**, as the G9’s EDID format appears to be unconventional.

Now, everything is working as expected—**240Hz, VRR, and HDR enabled without flickering or ghosting!** 🚀
