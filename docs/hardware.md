# Supported hardware and prerequisites

## Validated configuration

- iPod Video, 5th generation (`ipodvideo` Rockbox target)
- iFlash Solo adapter
- 128 GB SDXC card reporting exactly 249,737,216 sectors of 512 bytes
- Linux host with a reliable external SD-card reader
- A compatible source disk that already contains the required boot layout and
  Rockbox bootloader

The replacement display, case, click wheel, and other cosmetic parts do not
affect the disk layout. A marginal ZIF ribbon, iFlash socket, or connector can
still cause sector-zero errors even when the card is healthy.

## Required commands

The scripts use standard Linux tools plus:

- `lsblk`, `findmnt`, `blockdev`, and `partprobe` (util-linux/parted)
- `dd` and `sha256sum` (coreutils)
- `mkfs.fat` and `fsck.fat` (dosfstools)
- `unzip`
- `udevadm`

## Unsupported without further testing

- iPod Classic 6G/7G, Nano, Mini, Shuffle, or Touch
- Mac/HFS-formatted iPods
- Cards that do not report exactly 249,737,216 sectors
- Different boot/system-partition geometry
- Writing the partition table through an unreliable iPod USB bridge

Do not defeat a size or geometry check merely to make a command continue.
