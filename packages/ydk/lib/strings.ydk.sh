#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:strings() {
    trim() {
        local STR="$1" && [ -z "$STR" ] && STR="$(cat)" && [ -z "$STR" ] && return 1
        echo "$STR" | awk '{$1=$1};1'
    }
    contains() {
        local STR="$1" && [ -z "$STR" ] && STR="$(cat)" && [ -z "$STR" ] && return 1
        local SUB="$2"
        echo "$STR" | grep -- "$SUB" >/dev/null 2>&1
    }
    endswith() {
        local STR="$1" && [ -z "$STR" ] && STR="$(cat)" && [ -z "$STR" ] && return 1
        local SUB="$2"
        echo "$STR" | grep -- "$SUB\$" >/dev/null 2>&1
    }
    startswith() {
        local STR="$1" && [ -z "$STR" ] && STR="$(cat)" && [ -z "$STR" ] && return 1
        local SUB="$2"
        echo "$STR" | grep -- "^$SUB" >/dev/null 2>&1
    }
    lowercase() {
        tr '[:upper:]' '[:lower:]'
    }
    uppercase() {
        tr '[:lower:]' '[:upper:]'
    }
    capitalize() {
        local STR="$1" && [ -z "$STR" ] && STR="$(cat)" && [ -z "$STR" ] && return 1
        echo "$STR" | sed 's/\b\(.\)/\u\1/g'
    }
    reverse() {
        rev
    }
    count_char() {
        local STR="$1" && [ -z "$STR" ] && STR="$(cat)" && [ -z "$STR" ] && return 1
        local CHAR="$2"
        local COUNT="${#STR}"
        local STRIPPED="${STR//"$CHAR"/}"
        local COUNT_STRIPPED="${#STRIPPED}"
        echo $((COUNT - COUNT_STRIPPED))
    }
    mask() {
        local STR="$1" && [ -z "$STR" ] && STR="$(cat)" && [ -z "$STR" ] && return 1
        local MASK="${2:-*}"
        local LENGTH="${#STR}"
        local MASK_LEN="${#MASK}"
        local MASKED=""
        for ((i = 0; i < LENGTH; i++)); do
            [ "$i" -lt 1 ] && MASKED+="${STR:i:1}" && continue
            [ "$i" -eq $((LENGTH - 1)) ] && MASKED+="${STR:i:1}" && continue
            MASKED+="${MASK:i%MASK_LEN:1}"
        done
        echo "$MASKED"
    }
    sanetize() {
        local STR="$1" && [ -z "$STR" ] && STR="$(cat)" && [ -z "$STR" ] && return 1
        {
            echo -n "$STR" |
                sed -e 's/[^a-zA-Z0-9]/_/g' \
                    -e 's/__*/_/g' \
                    -e 's/^_//g' \
                    -e 's/_$//g' \
                    -r "s/\x1B\[[0-9;]*[mK]//g" |
                sed 's/\x1b\[[0-9;]*m//g'
        } >&4
    }
    ydk:try "$@"
    return $?
}
# #!/usr/bin/env bash
# # shellcheck disable=SC2044,SC2155,SC2317
# strings() {
#     mask() {
#         local STR="$1" && [ -z "$STR" ] && STR="$(cat)" && [ -z "$STR" ] && return 1
#         local MASK="${2:-*}"
#         local LENGTH="${#STR}"
#         local MASK_LEN="${#MASK}"
#         local MASKED=""
#         for ((i = 0; i < LENGTH; i++)); do
#             [ "$i" -lt 1 ] && MASKED+="${STR:i:1}" && continue
#             [ "$i" -eq $((LENGTH - 1)) ] && MASKED+="${STR:i:1}" && continue
#             MASKED+="${MASK:i%MASK_LEN:1}"
#         done
#         echo "$MASKED"
#     }
#     __nnf "$@" || usage "strings" "$?" "tests" "$@" && return 1
# }
# (
#     export -f strings
# )
