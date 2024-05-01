#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:cache() {
    ydk:try "$@" 4>&1
    return $?
}
# cache:v1() {
#     [ -z "$YWT_PATH_CACHE" ] && YWT_PATH_CACHE="$(jq -r '.cache' <<<"$YWT_PATHS")"
#     [ ! -d "$YWT_PATH_CACHE" ] && mkdir -p "$YWT_PATH_CACHE"
#     [ ! -r "$YWT_PATH_CACHE" ] || [ ! -w "$YWT_PATH_CACHE" ] || [ ! -x "$YWT_PATH_CACHE" ] && {
#         __log error "cache: cannot read, write, or execute $YWT_PATH"
#     }
#     __key() {
#         local KEY="${1// /_}" && KEY="${KEY//[^a-zA-Z0-9_]/}"
#         local TMP_FILE="$(mktemp -u -t "ywt.cache.XXXXXXXXXX" --tmpdir="$YWT_PATH_CACHE")"
#         local KEY="${KEY}.$(basename "$TMP_FILE")"
#         echo "$KEY"
#     }
#     __get() {
#         local KEY="$(__key "$1")"
#         local FILE="$YWT_PATH_CACHE/$KEY"
#         [ -f "$FILE" ] && cat "$FILE"
#     }
#     __set() {
#         local KEY="$(__key "$1")" && shift
#         local FILE="$YWT_PATH_CACHE/$KEY"
#         local CONTENT="$1" && [ -z "$CONTENT" ] && CONTENT="$(cat)"
#         echo "$CONTENT" >"$FILE"
#     }
#     __delete() {
#         local KEY="$(__key "$1")"
#         local FILE="$YWT_PATH_CACHE/$KEY"
#         [ -f "$FILE" ] && rm -f "$FILE"
#     }
#     __clear() {
#         rm -rf "$YWT_PATH_CACHE" && mkdir -p "$YWT_PATH_CACHE"
#     }
#     case "$1" in
#     get) __get "$2" ;;
#     set) __set "$2" "$3" ;;
#     delete) __delete "$2" ;;
#     clear) __clear ;;
#     *) __nnf "$@" || usage "$?" "tests" "$@" && return 1 ;;
#     esac
# }
#!/usr/bin/env bash
# # shellcheck disable=SC2044,SC2155,SC2317
# cache() {
#     [ -z "$YWT_PATH_CACHE" ] && YWT_PATH_CACHE="$(jq -r '.cache' <<<"$YWT_PATHS")"
#     [ ! -d "$YWT_PATH_CACHE" ] && mkdir -p "$YWT_PATH_CACHE"
#     [ ! -r "$YWT_PATH_CACHE" ] || [ ! -w "$YWT_PATH_CACHE" ] || [ ! -x "$YWT_PATH_CACHE" ] && {
#         __log error "cache: cannot read, write, or execute $YWT_PATH"
#     }
#     __key() {
#         local KEY="${1// /_}" && KEY="${KEY//[^a-zA-Z0-9_]/}"
#         local TMP_FILE="$(mktemp -u -t "ywt.cache.XXXXXXXXXX" --tmpdir="$YWT_PATH_CACHE")"
#         local KEY="${KEY}.$(basename "$TMP_FILE")"
#         echo "$KEY"
#     }
#     __get() {
#         local KEY="$(__key "$1")"
#         local FILE="$YWT_PATH_CACHE/$KEY"
#         [ -f "$FILE" ] && cat "$FILE"
#     }
#     __set() {
#         local KEY="$(__key "$1")" && shift
#         local FILE="$YWT_PATH_CACHE/$KEY"
#         local CONTENT="$1" && [ -z "$CONTENT" ] && CONTENT="$(cat)"
#         echo "$CONTENT" >"$FILE"
#     }
#     __delete() {
#         local KEY="$(__key "$1")"
#         local FILE="$YWT_PATH_CACHE/$KEY"
#         [ -f "$FILE" ] && rm -f "$FILE"
#     }
#     __clear() {
#         rm -rf "$YWT_PATH_CACHE" && mkdir -p "$YWT_PATH_CACHE"
#     }    
#     case "$1" in
#     get) __get "$2" ;;
#     set) __set "$2" "$3" ;;
#     delete) __delete "$2" ;;
#     clear) __clear ;;
#     *) __nnf "$@" || usage "$?" "tests" "$@" && return 1 ;;
#     esac
# }
# (
#     export -f cache
# )
