# Complete preparation procedure

## 1. Identify every device

Connect only the source or target needed for the current step, then inspect it:

```bash
lsblk -o NAME,PATH,MODEL,SERIAL,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINTS
```

Device letters change between boots and USB connections. Never assume an old
`/dev/sdX` name is still correct.

## 2. Capture the private template

Use a known-compatible, unmounted source disk. The capture script verifies the
whole-disk size and both partition boundaries before reading the first 160,650
sectors.

```bash
sudo scripts/capture-template.sh /dev/sdX private/ipod5-template.img
```

The script also creates `private/ipod5-template.img.sha256`. Keep both files in
private backup storage. The template contains the boot region copied from the
source device.

## 3. Inspect before writing

```bash
scripts/inspect-template.sh private/ipod5-template.img
```

Require all geometry checks to pass. The expected template size is 82,252,800
bytes and its second partition begins immediately after the final image sector.

## 4. Prepare the replacement card

Use a reliable external card reader. Ensure the target and all of its
partitions are unmounted, then run:

```bash
sudo scripts/prepare-card.sh private/ipod5-template.img /dev/sdY
```

The script prints the resolved model, serial, capacity, and destructive target.
To continue, type the exact whole-device path when prompted. It writes the
template, asks the kernel to reread the partition table, creates a fresh FAT32
filesystem labeled `IPOD`, and performs a read-only filesystem check.

## 5. Install Rockbox

Download the build for the `ipodvideo` target from the official Rockbox site.
Mount partition 2, then run:

```bash
scripts/install-rockbox.sh /path/to/rockbox-ipodvideo.zip /path/to/IPOD
```

The installer verifies that the archive contains `.rockbox/rockbox.ipod`, that
the destination is a mount point, and that it is writable before extraction.

## 6. Verify and boot

Flush writes and unmount the volume:

```bash
sync
udisksctl unmount -b /dev/sdY2
sudo fsck.fat -n -v /dev/sdY2
```

Require a successful final check. Install the card in the iFlash socket until
the push-push mechanism clicks and retains it. Boot Rockbox several times
before copying a music library.

## 7. Copy personal media separately

Rockbox can read ordinary folders copied to the FAT32 data volume. For example:

```bash
rsync -rlt --modify-window=1 --omit-dir-times --no-perms --no-owner \
  --no-group --partial --info=progress2 /path/to/library/ /path/to/IPOD/Music/
sync
```

This example intentionally omits `--delete`.
