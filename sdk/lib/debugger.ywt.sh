#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
debugger() {
    YWT_LOG_CONTEXT="debugger"
    watch() {
        tail -f "$YWT_FIFO"
        # listen to YWT_FIFO
        # while read -r line; do
        #     echo "Received: $line" 1>&2
        # done <"$YWT_FIFO"
        # [ "$YWT_DEBUG" == true ] && (
        #     tail -f "$YWT_FIFO" | while IFS= read -r LINE || [ -n "$LINE" ]; do
        #         [ -z "$YWT_DEBUG" ] || [ "$YWT_DEBUG" == false ] && continue
        #         if [ -n "$(type -t "logger")" ] && [ "$(type -t "$FUNC")" = function ]; then
        #             #logger debug "$LINE" #1>&2
        #             echo "logger - $LINE" #1>&2
        #         else
        #             echo "echo - $LINE" #1>&2
        #         fi
        #     done
        # ) &
    }
    _verbose() {
        echo "$1" 1>&2
    }
    if ioc __nnf "$@"; then return 0; fi
    usage "$?" "debugger" "$@" && return 1
}
