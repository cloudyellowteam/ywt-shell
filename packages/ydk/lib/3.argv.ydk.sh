#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:argv() {
    values() {
        [ -n "$YDK_ARGV" ] && echo "$YDK_ARGV" | jq -c . && return 0
        YDK_POSITIONAL=()
        export YDK_ARGV=$(
            {
                local JSON="{" && local FIRST=true
                while [[ $# -gt 0 ]]; do
                    local FLAG="$1"
                    [[ "$FLAG" != --* ]] && [[ "$FLAG" != -* ]] && YDK_POSITIONAL+=("$1") && shift && continue
                    local KEY=${FLAG#--} && KEY=${KEY#-} && KEY=${KEY%%=*} && KEY=${KEY%%:*}
                    local VALUE=${FLAG#*=} && VALUE=${VALUE#*:} && VALUE=${VALUE#*=} && VALUE=${VALUE#--} && VALUE=${VALUE#-}
                    [[ "$KEY" == "$VALUE" ]] && VALUE=true
                    [[ -z "$VALUE" ]] && VALUE=true
                    [[ "$VALUE" != true ]] && [[ "$VALUE" != false ]] && [[ "$VALUE" =~ ^[0-9]+$ ]] && VALUE="\"$VALUE\""
                    [ "$FIRST" == true ] && FIRST=false || JSON+=","
                    JSON+="\"$KEY\":\"$VALUE\"" && shift
                done
                JSON+="}"
                echo "$JSON"
            }
        ) && readonly YDK_ARGV
        echo "$YDK_ARGV" | jq -rc .
        return 0
    }
    form() {
        [ -n "$YDK_FORM" ] && echo "$YDK_FORM" | jq -c . && return 0
        YDK_POSITIONAL=()
        export YDK_FORM=$({
            local JSON="{" && local FIRST=true
            while [[ $# -gt 0 ]]; do
                local PARAM="$1"
                [[ "$PARAM" != kv=* ]] && YDK_POSITIONAL+=("$1") && shift && continue
                local KEY=${PARAM#kv=}
                local VALUE=${KEY#*:} && VALUE=${VALUE#*:} && VALUE=${VALUE#=}
                KEY=${KEY%%:*}
                [ "$KEY" == "$VALUE" ] && VALUE=true
                [ -z "$VALUE" ] && VALUE=true
                [ "$FIRST" == true ] && FIRST=false || JSON+=","
                JSON+="\"$KEY\":\"$VALUE\"" && shift
            done
            JSON+="}"
            echo "$JSON"
        }) && readonly YDK_FORM
        echo "$YDK_FORM" | jq -c .
    }
    flags() {
        YDK_POSITIONAL=()
        # [[ -n "$YDK_FLAGS" ]] && echo "$YDK_FLAGS" | jq -c . && return 0
        YDK_FLAGS=$(jq -n '{ "quiet": false, "trace": null, "logger": null, "debug": null, "output": null }')
        while [[ $# -gt 0 ]]; do
            case "$1" in
            -q | --quiet)
                export YDK_QUIET=true #&& readonly YDK_QUIET
                YDK_FLAGS=$(jq -n --argjson flags "$YDK_FLAGS" --arg quiet true '$flags | .quiet=$quiet')
                shift
                ;;
            -t | --trace)
                local VALUE=$(jq -r '.trace' <<<"$YDK_FLAGS")
                [ "$VALUE" == "null" ] && shift && continue
                [ "$VALUE" == true ] && VALUE="/tmp/ywt.trace"
                [ -p "$VALUE" ] && rm -f "$VALUE"
                export YDK_TRACE_FIFO="$VALUE"
                [ ! -p "$YDK_TRACE_FIFO" ] && mkfifo "$YDK_TRACE_FIFO" #&& readonly YDK_TRACE_FIFO
                YDK_LOGS+=("Trace FIFO enabled. In another terminal use 'tail -f $YDK_TRACE_FIFO' to watch logs or 'rapd debugger trace watch $YDK_TRACE_FIFO'.")
                YDK_FLAGS=$(jq -n --argjson flags "$YDK_FLAGS" --arg trace "$VALUE" '$flags | .trace=$trace')
                # exec 4>"$YDK_TRACE_FIFO"
                # set -x >&4
                shift
                ;;
            -l | --logger)
                local VALUE=$(jq -r '.logger' <<<"$YDK_FLAGS")
                [ "$VALUE" == "null" ] && shift && continue
                [ "$VALUE" == true ] && VALUE="/tmp/ywt.logger"
                [ -p "$YDK_LOGGER_FIFO" ] && rm -f "$YDK_LOGGER_FIFO"
                export YDK_LOGGER_FIFO="$VALUE"
                [ ! -p "$YDK_LOGGER_FIFO" ] && mkfifo "$YDK_LOGGER_FIFO" #&& readonly YDK_LOGGER_FIFO
                YDK_LOGS+=("Logger FIFO enabled. In another terminal use 'tail -f $YDK_LOGGER_FIFO' to watch logs or 'rapd logger watch $YDK_LOGGER_FIFO'.")
                YDK_FLAGS=$(jq -n --argjson flags "$YDK_FLAGS" --arg logger "$VALUE" '$flags | .logger=$logger')
                shift
                ;;
            -d | --debug)
                [ "$YDK_DEBUG" == true ] && shift && continue
                YDK_DEBUG=true && #readonly YDK_DEBUG
                    local VALUE=$(jq -r '.debug' <<<"$YDK_FLAGS")
                [ "$VALUE" == "null" ] && shift && continue
                [ "$VALUE" == true ] && VALUE="/tmp/ywt.debugger"
                [ -p "$YDK_DEBUG_FIFO" ] && rm -f "$YDK_DEBUG_FIFO"
                export YDK_DEBUG_FIFO="$VALUE"
                [ ! -p "$YDK_DEBUG_FIFO" ] && mkfifo "$YDK_DEBUG_FIFO" #&& readonly YDK_DEBUG_FIFO
                YDK_LOGS+=("Debug enabled. In another terminal use 'tail -f $YDK_DEBUG_FIFO' to watch logs or 'rapd debugger watch $YDK_DEBUG_FIFO'.")
                YDK_FLAGS=$(jq -n --argjson flags "$YDK_FLAGS" --arg debug "$VALUE" '$flags | .debug=$debug')
                shift
                ;;
            -o | --output)
                local VALUE=$(jq -r '.output' <<<"$YDK_FLAGS")
                [ "$VALUE" == "null" ] && shift && continue
                [ "$VALUE" == true ] && VALUE="/tmp/ywt.output"
                [ -p "$VALUE" ] && rm -f "$VALUE"
                export YDK_OUTPUT_FIFO="$VALUE"
                [ ! -p "$YDK_OUTPUT_FIFO" ] && mkfifo "$YDK_OUTPUT_FIFO" #&& readonly YDK_OUTPUT_FIFO
                YDK_LOGS+=("Output FIFO enabled. In another terminal use 'tail -f $YDK_OUTPUT_FIFO' to watch logs or 'rapd output watch $YDK_OUTPUT_FIFO'.")
                YDK_FLAGS=$(jq -n --argjson flags "$YDK_FLAGS" --arg output "$VALUE" '$flags | .output=$output')
                shift
                ;;
            -p* | --param*)
                YDK_POSITIONAL+=("$1")
                # params already parsed using __params
                shift
                ;;
            *)
                YDK_POSITIONAL+=("$1")
                shift
                ;;
            esac
        done
        export YDK_FLAGS      # && readonly YDK_FLAGS
        set -- "${YDK_POSITIONAL[@]}"
        return 0
    }
    ydk:try:nnf "$@"
    return $?
}