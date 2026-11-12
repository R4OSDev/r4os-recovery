#!/usr/bin/env sh
set -eu
exec pwsh -NoProfile -File "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/Build.ps1" "$@"
