#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ioc() {
    YWT_LOG_CONTEXT="ioc"
    nnf() {
        local FUNC=${1} && [ -z "$FUNC" ] && return 1
        FUNC=${FUNC#_} && FUNC=${FUNC#__} && FUNC="${FUNC//_/-5f}" && FUNC="${FUNC//-/-2d}" && FUNC="${FUNC// /_}"
        local ARGS=("${@:2}") # local ARGS=("${@}")
        if [ -n "$(type -t "$FUNC")" ] && [ "$(type -t "$FUNC")" = function ]; then
            # [[ "$FUNC" == "builder" ]] && echo "Running $FUNC with args: ${ARGS[*]}" 1>&2
            exec 3>&1
            trap 'exec 3>&-' EXIT
            local STATUS
            # $FUNC "${ARGS[@]}"
            local OUTPUT && OUTPUT=$($FUNC "${ARGS[@]}" 1>&3) # 2>&1
            STATUS=$?
            [ "$STATUS" -eq 0 ] && STATUS=success || STATUS=error
            #__debug "Function $FUNC status: $STATUS" # 1>&2
            exec 3>&-
            echo "$OUTPUT" # && echo "$OUTPUT" 1>&2
            # (echo "$OUTPUT" >$YWT_FIFO) & true
            return 0
        else
            # echo "Function $FUNC not found" | logger error
            return 1
        fi
    }
    resolve() {
        local FILE="${1:-}" && [ ! -f "$FILE" ] && return 1
        local FILE_NAME && FILE_NAME=$(basename -- "$FILE") && FILE_NAME="${FILE_NAME%.*}" && FILE_NAME=$(echo "$FILE_NAME" | tr '[:upper:]' '[:lower:]')
        _is_function "$FILE_NAME" && return 0
        __debug "Sourcing ${FILE_NAME} $FILE"
        # shellcheck source=/dev/null # echo "source $FILE" 1>&2 &&
        source "$FILE" && return 0
    }
    inject() {
        local LIB="${1:-}" && [ ! -d "$LIB" ] && return 1
        __debug "Injecting $LIB"
        while read -r FILE; do
            [[ "$FILE" = *"ioc.ywt.sh" ]] && continue
            _resolve "$FILE"
        done < <(find "$LIB" -type f -name "*.ywt.sh" | sort)
        return 0
    }
    __debug "ioc.ywt.sh called $*"
    nnf "$@" && return 0
    usage "$?" "ioc" "$@" && return 1
}
(
    export -f ioc
)
__debug "ioc.ywt.sh loaded"
