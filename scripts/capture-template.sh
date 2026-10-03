#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib.sh
source "$script_dir/lib.sh"

readonly expected_disk_sectors=249737216
readonly template_sectors=160650
readonly expected_p1_start=63
readonly expected_p1_sectors=160587

[[ $# -eq 2 ]] || die "Usage: sudo $0 SOURCE_DISK OUTPUT.img"
source_disk=$(readlink -f "$1")
output=$2

require_root
for command in blockdev dd lsblk sfdisk sha256sum; do need_command "$command"; done
require_block_device "$source_disk"
require_unmounted "$source_disk"
require_not_system_disk "$source_disk"
[[ ! -e $output && ! -e $output.sha256 ]] || die "Output already exists: $output"
[[ $(blockdev --getsz "$source_disk") -eq $expected_disk_sectors ]] || \
  die "Source must report exactly $expected_disk_sectors sectors."

mapfile -t parts < <(sfdisk --dump "$source_disk" | awk -F'[=, ]+' '/start=/ {print $4 ":" $6}')
[[ ${parts[0]:-} == "$expected_p1_start:$expected_p1_sectors" ]] || \
  die "Unexpected source boot/system partition geometry."
[[ ${parts[1]%%:*} == "$template_sectors" ]] || \
  die "Source data partition does not begin at sector $template_sectors."

mkdir -p -- "$(dirname -- "$output")"
printf 'Reading only sectors 0 through %s from %s\n' "$((template_sectors - 1))" "$source_disk"
dd if="$source_disk" of="$output.tmp" bs=512 count="$template_sectors" \
  iflag=fullblock status=progress
mv -- "$output.tmp" "$output"
sha256sum "$output" >"$output.sha256"
chmod 0600 "$output" "$output.sha256"
if [[ -n ${SUDO_UID:-} && -n ${SUDO_GID:-} ]]; then
  chown "$SUDO_UID:$SUDO_GID" "$output" "$output.sha256"
fi
printf 'Private template created: %s\n' "$output"
