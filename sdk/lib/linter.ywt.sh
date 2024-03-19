#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
linter() {
    echo "linter"
    # docker run --rm -v "$(pwd):/mnt" koalaman/shellcheck:latest shellcheck yourscript.sh
}
(
    export -f linter
)
