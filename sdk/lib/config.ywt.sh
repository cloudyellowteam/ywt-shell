#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
config() {
    usage() {
        echo "usage: config"
    }
    _nnf "$@" || usage "$?" "$@" && return 1
    return 0
    # local YWT_PATH_ROOT=$(dirname -- "$YWT_PATH_SRC")
    # local RADP_PROJECT_ROOT=$(dirname -- "$YWT_PATH_ROOT")
    # local YWT_PATH_TMP="${YWT_CONFIG_PATH_TMP:-"$(dirname -- "$(mktemp -d -u)")"}/ywt"
    # local YWT_PACKAGE=$(jq -c <"$YWT_PATH_SRC/package.json" 2>/dev/null)
    # local PACKAGES=$(find "$YWT_PATH_SRC/packages" -mindepth 1 -maxdepth 1 -type d -printf '%P\n' | jq -R -s -c 'split("\n") | map(select(length > 0))')
    # echo "{
    #         \"package\": $YWT_PACKAGE,
    #         \"env\": $(dotenv "$YWT_PATH_SRC/.env"),
    #         \"path\": $(paths),
    #         \"tools\": $(tools),
    #         \"packages\": $PACKAGES,
    #         \"program\": $(program "$@"),
    #         \"process\": $(process "$@"),
    #         \"hostinfo\": $(hostinfo),
    #         \"networkinfo\": $(networkinfo),
    #         \"userinfo\": $(userinfo),
    #         \"flags\": $(flags "$@"),
    #         \"params\": $(params "$@")
    #     }" | jq .
    # return 0
}
(
    export -f config
)
