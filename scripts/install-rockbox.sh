#!/usr/bin/env bash
set -euo pipefail

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

[[ $# -eq 2 ]] || die "Usage: $0 ROCKBOX.zip IPOD_MOUNTPOINT"
archive=$(readlink -f "$1")
destination=$(readlink -f "$2")

command -v findmnt >/dev/null 2>&1 || die "Required command not found: findmnt"
command -v unzip >/dev/null 2>&1 || die "Required command not found: unzip"
[[ -f $archive ]] || die "Archive not found: $archive"
[[ -d $destination ]] || die "Destination not found: $destination"
findmnt -T "$destination" >/dev/null || die "Destination is not on a mounted filesystem."
mount_target=$(findmnt -nro TARGET -T "$destination")
[[ $mount_target == "$destination" ]] || die "Destination must be the mount root: $mount_target"
[[ -w $destination ]] || die "Destination is not writable: $destination"
unzip -Z1 "$archive" | grep -qx '.rockbox/rockbox.ipod' || \
  die "Archive is not a Rockbox ipodvideo build (.rockbox/rockbox.ipod missing)."

unzip -o "$archive" -d "$destination"
sync
[[ -f $destination/.rockbox/rockbox.ipod ]] || die "Rockbox binary was not installed."
printf 'Rockbox installed at %s/.rockbox\n' "$destination"
