#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
config() {
    usage() {
        echo "usage: config"
    }
    nnf "$@" || usage "$?" "$@" && return 1
    return 0
    # local RAPD_PATH_ROOT=$(dirname -- "$RAPD_PATH_SRC")
    # local RADP_PROJECT_ROOT=$(dirname -- "$RAPD_PATH_ROOT")
    # local RAPD_PATH_TMP="${RAPD_CONFIG_PATH_TMP:-"$(dirname -- "$(mktemp -d -u)")"}/rapd"
    # local RAPD_PACKAGE=$(jq -c <"$RAPD_PATH_SRC/package.json" 2>/dev/null)
    # local PACKAGES=$(find "$RAPD_PATH_SRC/packages" -mindepth 1 -maxdepth 1 -type d -printf '%P\n' | jq -R -s -c 'split("\n") | map(select(length > 0))')
    # echo "{
    #         \"package\": $RAPD_PACKAGE,
    #         \"env\": $(dotenv "$RAPD_PATH_SRC/.env"),
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
