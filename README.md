# Rockbox Image Builder for iPod Video 5G

This project documents a tested Linux method for building a Rockbox recovery
card for an iPod Video (5th generation) fitted with an iFlash Solo and a
128 GB SDXC card.

The method was validated on one assembled device with this exact geometry:

| Region | Start sector | Sector count |
|---|---:|---:|
| Whole 128 GB card | 0 | 249,737,216 |
| Boot/system partition | 63 | 160,587 |
| FAT32 data partition | 160,650 | 249,576,565 |

## Important limitation

The bootable template is not created from nothing. It copies the first 160,650
sectors of an already prepared, compatible source disk, including its partition
map and boot/system partition. Each user must provide their own compatible
source disk.

This repository does not need or inspect a user's music. The captured template
ends exactly where the data partition begins.

## Warning

The write operation deliberately overwrites a complete block device. Selecting
the wrong device can permanently destroy unrelated data. This project is
experimental and provided **as is**, without warranty or a compatibility
guarantee. It has only been tested with the hardware and sector geometry above.

The scripts refuse mounted targets, the current system disk, unexpected image
sizes, and cards with a different sector count. These checks reduce risk; they
cannot make raw disk writes safe.

## What you need

- The validated iPod Video 5G/iFlash/128 GB hardware listed below
- One compatible source disk that already boots Rockbox
- One replacement 128 GB card reporting exactly 249,737,216 sectors
- A Linux computer and a reliable external card reader
- The official Rockbox archive for the `ipodvideo` target

The source disk is read only. The replacement card is completely erased.

## Workflow

### 1. Check compatibility

Read [hardware and prerequisites](docs/hardware.md). This version intentionally
refuses cards with a different capacity or partition geometry.

### 2. Find the source disk

Insert the known-working source disk and identify its whole-device path:

```bash
lsblk -o NAME,PATH,MODEL,SERIAL,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINTS
```

Unmount every partition on it. Substitute its whole-disk path for `/dev/sdX`.

### 3. Capture the boot-region template

```bash
sudo scripts/capture-template.sh /dev/sdX private/ipod5-template.img
```

This reads the source and creates a private 82,252,800-byte template plus its
SHA-256 checksum. It does not copy the source disk's FAT32 data partition.

### 4. Inspect the captured template

```bash
scripts/inspect-template.sh private/ipod5-template.img
```

Do not continue unless the command reports `Geometry check: PASS`.

### 5. Identify and prepare the replacement card

Insert the replacement card, run `lsblk` again, and substitute its whole-disk
path for `/dev/sdY`. This is the destructive step:

```bash
sudo scripts/prepare-card.sh private/ipod5-template.img /dev/sdY
```

The tool shows the selected model, serial, and device path and requires the
exact path to be typed again before writing. It then creates a clean FAT32
volume labeled `IPOD`.

### 6. Install Rockbox

Mount partition 2 of the replacement card and install the official Rockbox
archive:

```bash
scripts/install-rockbox.sh rockbox-ipodvideo-4.0.zip /path/to/IPOD
```

Unmount the card cleanly, install it in the iPod, and test several boots before
copying personal media.

See the [complete procedure](docs/procedure.md) before running any privileged
command.

## Script reference

| Script | Purpose | Writes a disk? |
|---|---|---|
| `capture-template.sh` | Reads the compatible source and creates the private template | No |
| `inspect-template.sh` | Checks template size, layout, and checksum | No |
| `prepare-card.sh` | Writes the template and formats the replacement data partition | **Yes** |
| `install-rockbox.sh` | Extracts a verified Rockbox archive to the mounted card | Writes files only |

## What is deliberately not in Git

- Boot-region templates or derived disk images
- Card backups and filesystem-recovery fragments
- Music, recordings, artwork, playlists, or Rockbox databases
- Downloaded Rockbox archives
- Device-specific logs and configuration state

## License

The original scripts and documentation in this repository are MIT licensed.
Rockbox and all other third-party components remain under their respective
licenses.
