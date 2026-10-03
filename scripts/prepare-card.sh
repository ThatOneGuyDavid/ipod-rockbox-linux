#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib.sh
source "$script_dir/lib.sh"

readonly expected_disk_sectors=249737216
readonly template_bytes=82252800
readonly template_sectors=160650

[[ $# -eq 2 ]] || die "Usage: sudo $0 TEMPLATE.img TARGET_DISK"
image=$(readlink -f "$1")
target=$(readlink -f "$2")

require_root
for command in blockdev dd findmnt fsck.fat lsblk mkfs.fat partprobe readlink stat udevadm; do
  need_command "$command"
done
[[ -f $image ]] || die "Template not found: $image"
[[ $(stat -c %s "$image") -eq $template_bytes ]] || \
  die "Template must be exactly $template_bytes bytes."
"$script_dir/inspect-template.sh" "$image" >/dev/null
require_block_device "$target"
require_unmounted "$target"
require_not_system_disk "$target"
[[ $(blockdev --getsz "$target") -eq $expected_disk_sectors ]] || \
  die "Target must report exactly $expected_disk_sectors sectors."

model=$(lsblk -dnro MODEL "$target" | sed 's/[[:space:]]*$//')
serial=$(lsblk -dnro SERIAL "$target" | sed 's/[[:space:]]*$//')
printf 'DESTRUCTIVE TARGET\n  device: %s\n  model:  %s\n  serial: %s\n' \
  "$target" "${model:-unknown}" "${serial:-unknown}"
printf 'Type the exact target path (%s) to erase it: ' "$target"
read -r confirmation
[[ $confirmation == "$target" ]] || die "Confirmation did not match; nothing was written."

dd if="$image" of="$target" bs=512 count="$template_sectors" conv=fsync status=progress
partprobe "$target"
udevadm settle
target_p2=$(partition_path "$target" 2)
[[ -b $target_p2 ]] || die "Partition did not appear: $target_p2"
require_unmounted "$target"
mkfs.fat -F 32 -n IPOD "$target_p2"
fsck.fat -n -v "$target_p2"
sync
printf 'Card prepared successfully. The new data volume is %s\n' "$target_p2"
