# Troubleshooting

## Do not continue after transport errors

Inspect current kernel messages:

```bash
journalctl -k -b --no-pager | \
  grep -Ei 'ipod|i/o error|crc|ecc|medium error|buffer i/o|reset high-speed'
```

CRC/ECC errors, sector-zero failures, missing partitions, or repeated USB resets
usually indicate a physical path problem. Check the ZIF ribbon and both of its
connectors first, then the iFlash socket/board.

## Card works externally but not inside the iPod

Passing `fsck.fat` in an external reader proves the card can be read through
that reader. It does not prove the ribbon, iFlash adapter, or logic-board
connector is reliable.

## Read-only FAT32 mount

An unclean shutdown may cause Linux to mount FAT32 read-only. Unmount it, run a
repair followed by a read-only verification, and only then remount it:

```bash
udisksctl unmount -b /dev/sdX2
sudo fsck.fat -a -v /dev/sdX2
sudo fsck.fat -n -v /dev/sdX2
```

`fsck.fat -a` can return status 1 after correcting errors. The final `-n` pass
must succeed.
