#!/bin/sh
set -eu
library_root=$(CDPATH= cd "$(dirname "$0")" && pwd -P)
exec pwsh -NoProfile -File "$library_root/Build.ps1" "$@"
