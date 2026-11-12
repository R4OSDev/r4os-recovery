#!/bin/sh
set -eu
project_root=$(CDPATH= cd "$(dirname "$0")" && pwd -P)
exec pwsh -NoLogo -NoProfile -File "$project_root/Build.ps1" "$@"
