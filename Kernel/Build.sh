#!/bin/sh
set -eu
recovery_kernel_root=$(CDPATH= cd "$(dirname "$0")" && pwd -P)
exec "$recovery_kernel_root/../Build.sh" -Mode Kernel "$@"
