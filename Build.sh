#!/bin/sh
set -eu
recovery_root=$(CDPATH= cd "$(dirname "$0")" && pwd -P)
if ! command -v pwsh >/dev/null 2>&1; then
    echo 'PowerShell 7 (pwsh) is required. Run the workspace setup first.' >&2
    exit 1
fi
exec pwsh -NoLogo -NoProfile -File "$recovery_root/Build.ps1" "$@"
