#!/bin/sh
set -eu
script_root=$(CDPATH= cd "$(dirname "$0")" && pwd -P)
exec pwsh -NoLogo -NoProfile -File "$script_root/New-RustProject.ps1" "$@"
