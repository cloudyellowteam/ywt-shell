#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317,SC2120
# Continuous Secutiry Scanner
ydk:secops() {
    YDK_LOGGER_CONTEXT="secops"
    [[ -z "$YDK_SECOPS_SPECS" ]] && declare -A YDK_SECOPS_SPECS=(
        ["all"]="."
        ["count"]=". | length"
        ["query"]=".[] | select(.name == \$SCANNER_ID or .id == \$SCANNER_ID)"
        ["installed"]="
            .[] | 
            if .id == \$SCANNER_ID then 
                .installed = \$SCANNER_INSTALLED
            else 
                .installed = false
            end"
        ["available"]=".[] | select(.installed == true or .installed == \"true\")"
        ["unavailable"]=".[] | select(.installed == false or .installed == \"false\")"
        ["packages"]=".packages[]"
    ) && readonly YDK_SECOPS_SPECS
    ydk:log info "Continuous Security Operations"
    scanners() {
        local SCANNERS_FILE="/workspace/rapd-shell/assets/scanners.json"
        [ ! -f "$SCANNERS_FILE" ] && echo "[]" >&4 && ydk:log error "No scanners found" && return 1
        list() {
            ydk:log info "$(jq -cr "${YDK_SECOPS_SPECS[count]}" "$SCANNERS_FILE") scanners available"
            {
                while read -r SCANNER && [ -n "$SCANNER" ]; do
                    [ -z "$SCANNER" ] && continue
                    local SCANNER_ID=$(jq -r '.id' <<<"$SCANNER") && [ -z "$SCANNER_ID" ] && continue
                    local SCANNER_NAME=$(jq -r '.name' <<<"$SCANNER") && [ -z "$SCANNER_NAME" ] && continue
                    local SCANNER_INSTALLED=false && command -v "$SCANNER_NAME" 2>/dev/null 1>/dev/null && SCANNER_INSTALLED=true
                    # ydk:log info "Scanner $SCANNER_NAME is installed: $SCANNER_INSTALLED"
                    jq -rc \
                        --arg SCANNER_ID "$SCANNER_ID" \
                        --arg SCANNER_INSTALLED "$SCANNER_INSTALLED" \
                        "${YDK_SECOPS_SPECS[installed]}" "$SCANNERS_FILE"
                done < <(jq -c "${YDK_SECOPS_SPECS[all]} | .[]" "$SCANNERS_FILE")
            } | jq -rsc '.' >&4
            ydk:log success "Use 'scanners available' to list available scanners"
            return 0
        }
        get() {
            local SCANNER_ID=$1
            local SCANNER=$(
                jq -cr --arg SCANNER_ID "$SCANNER_ID" "${YDK_SECOPS_SPECS[query]}" <<<"$(list 4>&1)"
            )
            [ -z "$SCANNER" ] && echo "{}" >&4 && ydk:log error "Scanner ${SCANNER_ID} not found" && return 22
            jq -c . <<<"$SCANNER" >&4
            ydk:log success "Scanner found $(jq -cr '.name' <<<"$SCANNER")"
            return 0

        }
        available() {
            local SCANNERS=$(list 4>&1)
            local SCANNERS_INSTALLED=$(jq -cr "${YDK_SECOPS_SPECS[available]}" <<<"$SCANNERS")
            echo "$SCANNERS_INSTALLED" >&4
            local SCANNERS_INSTALLED_COUNT=$(jq -cr "${YDK_SECOPS_SPECS[count]}" <<<"$SCANNERS_INSTALLED") &&
                SCANNERS_INSTALLED_COUNT="${SCANNERS_INSTALLED_COUNT:-0}"
            [[ "$SCANNERS_INSTALLED_COUNT" -eq 0 ]] && ydk:log warn "No scanners available" && return 251
            [[ "$SCANNERS_INSTALLED_COUNT" -gt 0 ]] && ydk:log success "${SCANNERS_INSTALLED_COUNT} scanners available" && return 0
        }
        unavailable() {
            local SCANNERS=$(list 4>&1)
            local SCANNERS_UNINSTALLED=$(jq -cr "${YDK_SECOPS_SPECS[unavailable]}" <<<"$SCANNERS")
            echo "$SCANNERS_UNINSTALLED" >&4
            local SCANNERS_UNINSTALLED_COUNT=$(jq -cr "${YDK_SECOPS_SPECS[count]}" <<<"$SCANNERS_UNINSTALLED") &&
                SCANNERS_UNINSTALLED_COUNT="${SCANNERS_UNINSTALLED_COUNT:-0}"
            ydk:log success "${SCANNERS_UNINSTALLED_COUNT} scanners unavailable"
            return 0
        }
        manager() {
            local YDK_SECOPS_MANAGER_ACTION=$1 && [ -z "$YDK_SECOPS_MANAGER_ACTION" ] && return 22
            shift
            ydk:log info "SecOps Manager $YDK_SECOPS_MANAGER_ACTION"
            for SCANNER_NAME in "$@"; do
                local SCANNER=$(jq -c --arg SCANNER_ID "$SCANNER_NAME" "${YDK_SECOPS_SPECS[query]}" <<<"$(list 4>&1)")
                [ -z "$SCANNER" ] && echo "{}" >&4 && ydk:log error "Scanner ${SCANNER_NAME} not found" && return 22
                local SCANNER_ID=$(jq -r '.id' <<<"$SCANNER") && [ -z "$SCANNER_ID" ] && continue
                read -r -a SCANNER_PACKAGES <<<"$(jq -r '.packages[]' <<<"$SCANNER")" && [ -z "${SCANNER_PACKAGES[*]}" ] && continue
                local SCANNER_INSTALLED=false && command -v "$SCANNER_NAME" 2>/dev/null 1>/dev/null && SCANNER_INSTALLED=true
                ydk:log info "Scanner $SCANNER_NAME is installed: $SCANNER_INSTALLED, packages: ${SCANNER_PACKAGES[*]}"
                case "$YDK_SECOPS_MANAGER_ACTION" in
                install)
                    if [ "$SCANNER_INSTALLED" = false ]; then
                        # ydk:upm cli "$SCANNER_NAME" 4>&1
                        ydk:upm install "$SCANNER_NAME" 4>&1
                    fi
                    ;;
                uninstall)
                    if [ "$SCANNER_INSTALLED" = true ]; then
                        ydk:upm cli 4>&1
                    fi
                    ;;
                *)
                    ydk:log error "Unsupported action $YDK_SECOPS_MANAGER_ACTION"
                    return 22
                    ;;
                esac
            done
            return 0
        }
        install() {
            if ! manager install "$@"; then
                ydk:log error "Failed to install scanner $SCANNER_NAME"
                return 1
            fi
        }
        uninstall() {
            if ! manager uninstall "$@"; then
                ydk:log error "Failed to uninstall scanner $SCANNER_NAME"
                return 1
            fi
        }
        # state() {
        #     local SCANNER=$1
        #     local SCANNER_ID=$(jq -r '.id' <<<"$SCANNER")
        #     local SCANNER_NAME=$(jq -r '.name' <<<"$SCANNER")
        #     local SCANNER_INSTALLED=false && command -v "$SCANNER_NAME" 2>/dev/null && SCANNER_INSTALLED=true
        #     echo "Scanner $SCANNER_NAME is installed: $SCANNER_INSTALLED"
        #     if [ "$SCANNER_INSTALLED" = false ] && ! css:scanner:install "$SCANNER"; then
        #         ydk:log error "Failed to install scanner $SCANNER_NAME"
        #         return 1
        #     fi
        #     # jq -r '
        #     #     . |
        #     #     if .installed == false then
        #     #         "Scanner \(.name) is not installed"
        #     #     else
        #     #         "Scanner \(.name) is installed"
        #     #     end
        #     #     ' <<<"$SCANNER" #>&4
        # }
        ydk:try "$@"
        return $?
    }
    cli:v2() {
        [ -z "$1" ] && return 22
        local SCANNER=$(scanners get "$1" 4>&1)
        [ -z "$SCANNER" ] && return 22
        shift
        local SCANNER_CLI=$(jq -r '.scanner.cli' <<<"$SCANNER_ENDPOINT")
        [ -z "$SCANNER_CLI" ] && return 22
        local SCANNER_CMD=$(jq -r ".scanner.cli.cmd" <<<"$SCANNER_ENDPOINT")
        [ -z "$SCANNER_CMD" ] && return 22
        if ! command -v "$SCANNER_CMD" 2>/dev/null 1>/dev/null; then
            ydk:log error "Scanner $SCANNER_CMD is not installed"
            return 1
        fi
        read -r -a SCANNER_CMD_DEFAULT_ARGS <<<"$(jq -r '.scanner.cli.args[]' <<<"$SCANNER_ENDPOINT")"
        [ -z "${SCANNER_CMD_DEFAULT_ARGS[*]}" ] && return 22
        if ! {
            echo -n "{"
            echo -n "\"scanner\":$(jq -c '.scanner | del(.cli)' <<<"$SCANNER_ENDPOINT"),"
            echo -n "\"cmd\":["
            echo -n "\"$SCANNER_CMD\","
            {
                for i in "${!SCANNER_CMD_DEFAULT_ARGS[@]}"; do
                    case "${SCANNER_CMD_DEFAULT_ARGS[i]}" in
                    *\{\{.*\}\}*)
                        SCANNER_CMD_DEFAULT_ARGS[i]=$(ydk:interpolate "${SCANNER_CMD_DEFAULT_ARGS[i]}" "$@" 4>&1)
                        ;;
                    *) ;;
                    esac
                    if ydk:is number "${SCANNER_CMD_DEFAULT_ARGS[i]}"; then
                        echo -n "${SCANNER_CMD_DEFAULT_ARGS[i]},"
                    elif ydk:is boolean "${SCANNER_CMD_DEFAULT_ARGS[i]}"; then
                        echo -n "${SCANNER_CMD_DEFAULT_ARGS[i]},"
                    elif jq -e . <<<"${SCANNER_CMD_DEFAULT_ARGS[i]}" 2>/dev/null 1>/dev/null; then
                        echo -n "$(jq -c . <<<"${SCANNER_CMD_DEFAULT_ARGS[i]}"),"
                    else
                        echo -n "\"${SCANNER_CMD_DEFAULT_ARGS[i]}\","
                    fi

                done
            } | sed 's/,$//'
            echo -n "]"
            echo -n "}"
            return 0
        } | jq -c . 2>/dev/null >&4; then
            ydk:log error "Scanner $SCANNER_CMD cli unavailable"
            return 1
        fi
        return 0
    }
    cli:v1() {
        local SCANNER_ENDPOINT=$(ydk:secops:endpoint "$@" 4>&1)
        [ -z "$SCANNER_ENDPOINT" ] && return 22
        local API_SCANNER_PATH=$(jq -r '.path' <<<"$SCANNER_ENDPOINT")
        [ -z "$API_SCANNER_PATH" ] && return 22
        local SCANNER_CLI=$(jq -r '.scanner.cli' <<<"$SCANNER_ENDPOINT")
        [ -z "$SCANNER_CLI" ] && return 22
        local SCANNER_CMD=$(jq -r ".scanner.cli.cmd" <<<"$SCANNER_ENDPOINT")
        [ -z "$SCANNER_CMD" ] && return 22
        if ! command -v "$SCANNER_CMD" 2>/dev/null 1>/dev/null; then
            ydk:log error "Scanner $SCANNER_CMD is not installed"
            return 1
        fi
        read -r -a SCANNER_CMD_DEFAULT_ARGS <<<"$(jq -r '.scanner.cli.args[]' <<<"$SCANNER_ENDPOINT")"
        [ -z "${SCANNER_CMD_DEFAULT_ARGS[*]}" ] && return 22
        if ! {
            echo -n "{"
            echo -n "\"scanner\":$(jq -c '.scanner | del(.cli)' <<<"$SCANNER_ENDPOINT"),"
            echo -n "\"path\":\"$API_SCANNER_PATH\","
            echo -n "\"cmd\":["
            echo -n "\"$SCANNER_CMD\","
            {
                for i in "${!SCANNER_CMD_DEFAULT_ARGS[@]}"; do
                    case "${SCANNER_CMD_DEFAULT_ARGS[i]}" in
                    *\{\{.*\}\}*)
                        SCANNER_CMD_DEFAULT_ARGS[i]=$(ydk:interpolate "${SCANNER_CMD_DEFAULT_ARGS[i]}" "$@" 4>&1)
                        ;;
                    *) ;;
                    esac
                    if ydk:is number "${SCANNER_CMD_DEFAULT_ARGS[i]}"; then
                        echo -n "${SCANNER_CMD_DEFAULT_ARGS[i]},"
                    elif ydk:is boolean "${SCANNER_CMD_DEFAULT_ARGS[i]}"; then
                        echo -n "${SCANNER_CMD_DEFAULT_ARGS[i]},"
                    elif jq -e . <<<"${SCANNER_CMD_DEFAULT_ARGS[i]}" 2>/dev/null 1>/dev/null; then
                        echo -n "$(jq -c . <<<"${SCANNER_CMD_DEFAULT_ARGS[i]}"),"
                    else
                        echo -n "\"${SCANNER_CMD_DEFAULT_ARGS[i]}\","
                    fi

                done
            } | sed 's/,$//'
            echo -n "]"
            echo -n "}"
            return 0
        } | jq -c . 2>/dev/null >&4; then
            ydk:log error "Scanner $SCANNER_CMD cli unavailable"
            return 1
        fi
        return 0
    }
    secops:cli:arg() {
        {
            for ARG in "$@"; do
                case "$ARG" in
                *\{\{.*\}\}*)
                    echo -n "$(ydk:interpolate "$ARG" "$@" 4>&1),"
                    ;;
                *) ;;
                esac
                if ydk:is number "$ARG"; then
                    echo -n "$ARG,"
                elif ydk:is boolean "$ARG"; then
                    echo -n "$ARG,"
                elif jq -e . <<<"$ARG" 2>/dev/null 1>/dev/null; then
                    echo -n "$(jq -c . <<<"$ARG"),"
                else
                    echo -n "\"$ARG\","
                fi
            done
        } | sed 's/,$//' >&4
        return $?
    }
    cli() {
        local SCANNER_ENTRYPOINT=$(ydk:secops:entrypoint "$@" 4>&1)
        [ -z "$SCANNER_ENTRYPOINT" ] && return 22
        shift
        local SCANNER_CLI=$(jq -r '.scanner.cli' <<<"$SCANNER_ENTRYPOINT")
        [ -z "$SCANNER_CLI" ] && return 22
        local SCANNER_CMD=$(jq -r ".scanner.cli.cmd" <<<"$SCANNER_ENTRYPOINT")
        [ -z "$SCANNER_CMD" ] && return 22
        if ! command -v "$SCANNER_CMD" 2>/dev/null 1>/dev/null; then
            ydk:log error "Scanner $SCANNER_CMD is not installed"
            return 1
        fi
        read -r -a SCANNER_CMD_DEFAULT_ARGS <<<"$(jq -r '.scanner.cli.args[]' <<<"$SCANNER_ENTRYPOINT")"
        [ -z "${SCANNER_CMD_DEFAULT_ARGS[*]}" ] && return 22
        local SCANNER_CLI_METADATA=$({
            {
                echo -n "{"
                echo -n "\"scanner\":$(jq -c '.scanner | del(.cli)' <<<"$SCANNER_ENTRYPOINT"),"
                echo -n "\"cmd\":["
                echo -n "\"$SCANNER_CMD\","
                secops:cli:arg "${SCANNER_CMD_DEFAULT_ARGS[@]}" "$@" 4>&1
                echo -n ",\"\""
                echo -n "]"
                echo -n "}"
                return 0
            } >&4
        } 4>&1)
        if ! jq . 2>/dev/null <<<"${SCANNER_CLI_METADATA}"; then # >&4; then
            ydk:log error "Scanner $SCANNER_CMD cli unavailable"
            return 1
        fi
        [ -z "$SCANNER_CLI_METADATA" ] && return 22
        jq -c . <<<"$SCANNER_CLI_METADATA" # >&4
        read -r -a SCANNER_COMMAND <<<"$(jq -cr '.cmd[]' <<<"$SCANNER_CLI_METADATA")"
        jq -r '.cmd[]' <<<"$SCANNER_CLI_METADATA"
        echo "${#SCANNER_COMMAND[@]} ${SCANNER_COMMAND[*]}"
        [ -z "${SCANNER_COMMAND[*]}" ] && return 22
        [[ "${#SCANNER_COMMAND[@]}" -eq 0 ]] && return 22
        [[ "${SCANNER_COMMAND[0]}" == "null" ]] && return 22
        local SCANNER_CMD=${SCANNER_COMMAND[0]}
        local SCANNER_CMD_ARGS=("${SCANNER_COMMAND[@]:1}")
        
        {
            $SCANNER_CMD "${SCANNER_CMD_ARGS[@]}"
            # "${SCANNER_COMMAND[@]}" 2>/dev/null
        } 2>/dev/null &
        local SCANNER_PID=$!
        trap 'kill '"$SCANNER_PID"' 2>/dev/null' EXIT
        ydk:await spin "$SCANNER_PID" "Running scanner $SCANNER_CMD (${SCANNER_PID})"
        return $?
        # {
        #     $SCANNER_CMD "${SCANNER_CMD_DEFAULT_ARGS[@]}" "${SCANNERS_API_ARGS[@]}" 2>/dev/null
        # } 2>/dev/null &
        # local SCANNER_PID=$!
        # trap 'kill '"$SCANNER_PID"' 2>/dev/null' EXIT
        # ydk:await spin "$SCANNER_PID" "Running scanner $SCANNER_CMD (${SCANNER_PID})"
        # return 0
        # return 0
    }
    ydk:secops:entrypoint() {
        [ -z "$1" ] && return 22
        local API_SCANNER_NAME=$(cut -d'/' -f1 <<<"$1")
        local API_SCANNER_PATH=${1#"$API_SCANNER_NAME"} && API_SCANNER_PATH=${API_SCANNER_PATH#/}
        # echo "ydk:secops:entrypoint $* API_SCANNER=$API_SCANNER API_SCANNER_PATH=$API_SCANNER_PATH"
        [ -z "$API_SCANNER_NAME" ] && return 22
        local API_SCANNER=$(scanners get "$API_SCANNER_NAME" 4>&1)
        [ -z "$API_SCANNER" ] && return 22
        # [ -z "$API_SCANNER_PATH" ] && return 22
        if ! {
            jq -cr \
                --arg API_SCANNER_NAME "$API_SCANNER_NAME" \
                --arg API_SCANNER_PATH "${API_SCANNER_PATH:-""}" \
                --argjson SCANNER "$(jq -c . <<<"$API_SCANNER")" \
                '
                {
                    "scanner":$SCANNER,
                    "path":$API_SCANNER_PATH,
                    "name":$API_SCANNER_NAME
                }' <<<"{}"
        } 2>/dev/null >&4; then
            ydk:log error "Scanner $SCANNER_CMD endpoint unavailable"
            return 1
        fi
        return 0
    }
    api() {
        ydk:secops:endpoint() {
            [ -z "$1" ] && return 22
            local API_SCANNER=$(cut -d'/' -f1 <<<"$1")
            local API_SCANNER_PATH=${1#"$API_SCANNER"} && API_SCANNER_PATH=${API_SCANNER_PATH#/}
            [ -z "$API_SCANNER" ] && return 22
            [ -z "$API_SCANNER_PATH" ] && return 22
            shift
            local SCANNER=$(scanners get "$API_SCANNER" 4>&1)
            [ -z "$SCANNER" ] && return 22
            jq -cr \
                --arg API_SCANNER "$API_SCANNER" \
                --arg API_SCANNER_PATH "$API_SCANNER_PATH" \
                --argjson SCANNER "$(jq -c . <<<"$SCANNER")" \
                '
                {
                    "scanner":$SCANNER,
                    "path":$API_SCANNER_PATH
                }' <<<"$SCANNER" 2>/dev/null >&4
            return $?
            # if ! ; then
            #     ydk:log error "Scanner $SCANNER_CMD endpoint unavailable"
            #     return 1
            # fi
            # jq '{}' >&4
            # return 0
        }
        ydk:secops:entrypoint "$@" 4>&1
        # local SCANNER_CLI=$(cli "$@" 4>&1)
        # [ -z "$SCANNER_CLI" ] && return 22
        # jq . <<<"$SCANNER_CLI" #>&4
        return 0
        # [ -z "$1" ] && return 22
        # local API_SCANNER=$(cut -d'/' -f1 <<<"$1")
        # local API_SCANNER_PATH=${1#"$API_SCANNER"} && API_SCANNER_PATH=${API_SCANNER_PATH#/}
        # [ -z "$API_SCANNER" ] && return 22
        # [ -z "$API_SCANNER_PATH" ] && return 22
        # shift
        # local SCANNER=$(scanners get "$API_SCANNER" 4>&1)
        # [ -z "$SCANNER" ] && return 22
        # local SCANNER_CLI=$(jq -r '.cli' <<<"$SCANNER")
        # [ -z "$SCANNER_CLI" ] && return 22
        # local SCANNER_CMD=$(jq -r ".cli.cmd" <<<"$SCANNER")
        # [ -z "$SCANNER_CMD" ] && return 22
        # if ! command -v "$SCANNER_CMD" 2>/dev/null 1>/dev/null; then
        #     ydk:log error "Scanner $SCANNER_CMD is not installed"
        #     return 1
        # fi
        # read -r -a SCANNER_CMD_DEFAULT_ARGS <<<"$(jq -r '.cli.args[]' <<<"$SCANNER")"
        # [ -z "${SCANNER_CMD_DEFAULT_ARGS[*]}" ] && return 22
        # local SCANNER_API=$(jq -r '.api' <<<"$SCANNER")
        # [ -z "$SCANNER_API" ] && return 22
        # read -r -a SCANNERS_API_ARGS <<<"$(jq -r '.api["'"$API_SCANNER_PATH"'"][]' <<<"$SCANNER" 2>/dev/null)"
        # # echo "SCANNERS_API_ARGS: ${SCANNERS_API_ARGS[*]}"
        # [ -z "${SCANNERS_API_ARGS[*]}" ] && return 22
        # # SCANNERS_API_ARGS=$(__interpolate "${SCANNERS_API_ARGS[@]}" "$@" 4>&1)
        # # [ -z "${SCANNERS_API_ARGS[*]}" ] && return 22
        # for ARG in "$@"; do
        #     if [[ $ARG == --*=* ]]; then
        #         local KEY=${ARG%%=*}
        #         local VALUE=${ARG#*=}
        #         KEY=${KEY#--}
        #         KEY=${KEY//./}
        #         for i in "${!SCANNERS_API_ARGS[@]}"; do
        #             # arg is {{.target}}
        #             SCANNERS_API_ARGS[i]=${SCANNERS_API_ARGS[i]//\{\{.$KEY\}\}/$VALUE}
        #         done
        #         # SCANNERS_API_ARGS=( "${SCANNERS_API_ARGS[@]/$KEY/$VALUE}" )
        #         # REPLACEMENTS[$KEY]=$VALUE
        #     fi
        # done
        # # echo "SCANNERS_API_ARGS: ${SCANNERS_API_ARGS[*]}"
        # # echo "API_SCANNER_PATH: $API_SCANNER_PATH"
        # {
        #     echo -n "{"
        #     echo -n "\"scanner\":$SCANNER,"
        #     echo -n "\"api\":$SCANNER_API,"
        #     echo -n "\"cmd\":["
        #     echo -n "\"$SCANNER_CMD\","
        #     {
        #         for i in "${!SCANNER_CMD_DEFAULT_ARGS[@]}"; do
        #             echo -n "\"${SCANNER_CMD_DEFAULT_ARGS[i]}\","
        #         done
        #         for i in "${!SCANNERS_API_ARGS[@]}"; do
        #             echo -n "\"${SCANNERS_API_ARGS[i]}\","
        #         done
        #     } | sed 's/,$//'
        #     echo -n "]"
        #     echo -n "}"
        # } | jq -c . >&4

        # # echo "$SCANNER_CMD ${SCANNER_CMD_DEFAULT_ARGS[*]} ${SCANNERS_API_ARGS[*]}"
        # {
        #     $SCANNER_CMD "${SCANNER_CMD_DEFAULT_ARGS[@]}" "${SCANNERS_API_ARGS[@]}" 2>/dev/null
        # } 2>/dev/null &
        # local SCANNER_PID=$!
        # trap 'kill '"$SCANNER_PID"' 2>/dev/null' EXIT
        # ydk:await spin "$SCANNER_PID" "Running scanner $SCANNER_CMD (${SCANNER_PID})"
        # return 0
        # jq -cr . <<<"$SCANNER_API" # >&4
        # {"cli/version":["--version"],"asset/filesystem/count":["{{.target}}"],"asset/filesystem/count-by-lang":["--by-file","{{.target}}"]}
        # case "$1" in
        # "cli/version") ;;
        # "asset/filesystem/count")
        #     # echo "${#SCANNERS_API_ARGS[@]} ${SCANNERS_API_ARGS[*]}"
        #     # __interpolate "${SCANNERS_API_ARGS[@]}" "$@" 4>&1
        #     # return 0
        #     ;;
        # *)
        #     ydk:log error "Unsupported API $1"
        #     # return 22
        #     ;;
        # esac

        # {
        #     $SCANNER_CMD "${SCANNER_CMD_DEFAULT_ARGS[@]}" "${SCANNERS_API_ARGS[@]}"
        # } 2>/dev/null #1>&4

        # return 0
    }
    ydk:try "$@"
    return $?
}

# ydk:css() {
#     css:scanner:state() {
#         local SCANNER=$1
#         local SCANNER_ID=$(jq -r '.id' <<<"$SCANNER")
#         local SCANNER_NAME=$(jq -r '.name' <<<"$SCANNER")
#         local SCANNER_INSTALLED=false && command -v "$SCANNER_NAME" 2>/dev/null && SCANNER_INSTALLED=true
#         echo "Scanner $SCANNER_NAME is installed: $SCANNER_INSTALLED"
#         if [ "$SCANNER_INSTALLED" = false ] && ! css:scanner:install "$SCANNER"; then
#             ydk:log error "Failed to install scanner $SCANNER_NAME"
#             return 1
#         fi
#         # jq -r '
#         #     . |
#         #     if .installed == false then
#         #         "Scanner \(.name) is not installed"
#         #     else
#         #         "Scanner \(.name) is installed"
#         #     end
#         #     ' <<<"$SCANNER" #>&4
#     }
#     css:scanner() {
#         local SCANNER=$(css:get "$1" 4>&1)
#         [ -z "$SCANNER" ] && return 22
#         SCANNER="$(jq -c '.' <<<"$SCANNER")"
#         # jq . "$SCANNER"
#         # ydk:upm detect 4>&1
#         # ydk:upm vendor "ubuntu" 4>&1
#         case "$2" in
#         state)
#             css:scanner:state "$SCANNER"
#             return $?
#             ;;
#         *)
#             ydk:trow 255 "Unsupported command $1"
#             ;;
#         esac
#         return 0
#     }
#     ydk:try "$@"
#     return $?
# }
