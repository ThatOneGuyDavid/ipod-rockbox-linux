#!/usr/bin/env bash

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

need_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

require_root() {
  [[ ${EUID:-$(id -u)} -eq 0 ]] || die "Run this command as root (for example, with sudo)."
}

require_block_device() {
  [[ -b $1 ]] || die "Not a block device: $1"
  [[ $(lsblk -dnro TYPE "$1") == disk ]] || die "Expected a whole-disk device: $1"
}

require_unmounted() {
  local device=$1
  if lsblk -nrpo MOUNTPOINT "$device" | grep -q '[^[:space:]]'; then
    die "$device or one of its partitions is mounted. Unmount it first."
  fi
}

require_not_system_disk() {
  local device root_majmin ancestor_majmin
  device=$(readlink -f "$1")
  root_majmin=$(findmnt -nro MAJ:MIN /)
  [[ -n $root_majmin ]] || die "Could not identify the system root device."

  while IFS= read -r ancestor_majmin; do
    [[ $ancestor_majmin != "$root_majmin" ]] || \
      die "Refusing to use a device in the system-root storage chain: $device"
  done < <(lsblk -snro MAJ:MIN "$device")
}

partition_path() {
  local device=$1 number=$2
  if [[ $device =~ [0-9]$ ]]; then
    printf '%sp%s\n' "$device" "$number"
  else
    printf '%s%s\n' "$device" "$number"
  fi
}
