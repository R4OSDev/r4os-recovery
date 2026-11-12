#!/bin/sh
set -eu
compiler_root=$(CDPATH= cd "$(dirname "$0")" && pwd -P)
exec pwsh -NoLogo -NoProfile -File "$compiler_root/Build.ps1" "$@"
