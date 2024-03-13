#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ioc() {    
    YWT_LOG_CONTEXT="ioc"
    echo "ioc"
}
(
    export -f ioc
)
