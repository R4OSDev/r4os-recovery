#!/usr/bin/env sh
set -eu
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec pwsh -NoLogo -NoProfile -File "$script_dir/New-Project.ps1" "$@"
