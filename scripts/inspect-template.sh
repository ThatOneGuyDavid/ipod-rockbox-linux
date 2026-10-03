#!/usr/bin/env bash
set -euo pipefail

readonly expected_bytes=82252800
readonly expected_p1_start=63
readonly expected_p1_sectors=160587
readonly expected_p2_start=160650

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

[[ $# -eq 1 ]] || die "Usage: $0 TEMPLATE.img"
image=$1
[[ -f $image ]] || die "Template not found: $image"
[[ $(stat -c %s "$image") -eq $expected_bytes ]] || \
  die "Template must be exactly $expected_bytes bytes."

command -v sfdisk >/dev/null 2>&1 || die "Required command not found: sfdisk"
command -v sha256sum >/dev/null 2>&1 || die "Required command not found: sha256sum"

mapfile -t parts < <(sfdisk --dump "$image" | awk -F'[=, ]+' '/start=/ {print $4 ":" $6}')
[[ ${parts[0]:-} == "$expected_p1_start:$expected_p1_sectors" ]] || \
  die "Unexpected boot/system partition geometry: ${parts[0]:-missing}"
[[ ${parts[1]:-} == "$expected_p2_start:249576565" ]] || \
  die "Unexpected data partition geometry: ${parts[1]:-missing}"

printf 'Template: %s\n' "$image"
printf 'Size: %s bytes (%s sectors)\n' "$expected_bytes" "$expected_p2_start"
sha256sum "$image"
printf 'Geometry check: PASS\n'
