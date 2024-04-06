#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
YWT_SRC="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
[ -z "$YWT_SRC" ] && echo "Failed to determine the script's directory" && exit 1
[ ! -f "${YWT_SRC}/sdk/sdk.sh" ] && echo "Failed to locate sdk.sh" && exit 1
# shellcheck source=/dev/null
source "${YWT_SRC}/sdk/sdk.sh"

if [ "$#" -gt 0 ]; then
    ywt "$@"
    return $?
fi
# ywt usage
# return 1
