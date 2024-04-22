#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317,SC2120
# Continuous Secutiry Scanner
ydk:secops() {
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
            end
        "
        ["available"]=".[] | select(.installed == true or .installed == \"true\")"
        ["unavailable"]=".[] | select(.installed == false or .installed == \"false\")"
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
                    local SCANNER_INSTALLED=false && command -v "$SCANNER_NAME" 2>/dev/null && SCANNER_INSTALLED=true
                    ydk:log info "Scanner $SCANNER_NAME is installed: $SCANNER_INSTALLED"
                    jq -rc \
                        --arg SCANNER_ID "$SCANNER_ID" \
                        --arg SCANNER_INSTALLED "$SCANNER_INSTALLED" \
                        "${YDK_SECOPS_SPECS[installed]}" "$SCANNERS_FILE"
                done < <(jq -c "${YDK_SECOPS_SPECS[all]} | .[]" "$SCANNERS_FILE")
            } | jq -rsc '.' >&4
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
            ydk:log success "${SCANNERS_INSTALLED_COUNT} scanners available"
            return 0
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
            for SCANNER in "$@"; do
                local SCANNER_ID=$(jq -r '.id' <<<"$SCANNER") && [ -z "$SCANNER_ID" ] && continue
                local SCANNER_NAME=$(jq -r '.name' <<<"$SCANNER") && [ -z "$SCANNER_NAME" ] && continue
                local SCANNER_INSTALLED=false && command -v "$SCANNER_NAME" 2>/dev/null && SCANNER_INSTALLED=true
                case "$YDK_SECOPS_MANAGER_ACTION" in
                install)
                    if [ "$SCANNER_INSTALLED" = false ]; then
                        echo "Trying install $SCANNER_NAME"
                        ydk:upm cli 4>&1
                    fi
                    ;;
                uninstall)
                    if [ "$SCANNER_INSTALLED" = true ]; then
                        echo "Trying uninstall $SCANNER_NAME"
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
