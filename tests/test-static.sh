#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

for script in "$repo_root"/scripts/*.sh; do
  bash -n "$script"
done

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "$repo_root"/scripts/*.sh
else
  printf 'shellcheck not installed; bash syntax checks passed.\n'
fi

printf 'Static tests: PASS\n'
