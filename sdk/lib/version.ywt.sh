#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
version() {
    echo "0.0.1"
}
(
    export -f version
)