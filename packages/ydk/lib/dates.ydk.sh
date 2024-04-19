#!/usr/bin/env bash
# # shellcheck disable=SC2317,SC2155
# dates() {
#     add() {
#         local ARGS=()
#         while [[ $# -gt 0 ]]; do
#             case "$1" in
#             -d | --datetime) local DATETIME=$(date -Iseconds -d "$2") && shift 2 ;;
#             -y | --years) local YEARS="$2" && shift 2 ;;
#             -m | --months) local MONTHS="$2" && shift 2 ;;
#             -D | --days) local DAYS="$2" && shift 2 ;;
#             -h | --hours) local HOURS="$2" && shift 2 ;;
#             -M | --minutes) local MINUTES="$2" && shift 2 ;;
#             -s | --seconds) local SECONDS="$2" && shift 2 ;;
#             *) ARGS+=("$1") && shift ;;
#             esac
#         done
# 
#         [ -z "$DATETIME" ] && DATETIME=${ARGS[0]:-"$(date -Iseconds -d "$(date +'%F %T')")"}
#         [ -z "$YEARS" ] && YEARS=${ARGS[1]:-0}
#         [ -z "$MONTHS" ] && MONTHS=${ARGS[2]:-0}
#         [ -z "$DAYS" ] && DAYS=${ARGS[3]:-0}
#         [ -z "$HOURS" ] && HOURS=${ARGS[4]:-0}
#         [ -z "$MINUTES" ] && MINUTES=${ARGS[5]:-0}
#         [ -z "$SECONDS" ] && SECONDS=${ARGS[6]:-0}
#         local DATE=$(date -Iseconds -d "$DATETIME $YEARS years $MONTHS months $DAYS days $HOURS hours $MINUTES minutes $SECONDS seconds")
#         echo "$DATE"
#         unset ARGS DATETIME YEARS MONTHS DAYS HOURS MINUTES SECONDS DATE
#         return "$?"
#     }
#     parse() {
#         local DATE="${1:-$(date +'%F %T')}"
#         {
#             echo -n "{"
#             echo -n "\"timezone\":\"$(date -d "$DATE" +%Z)\","
#             echo -n "\"date\":\"$DATE\","
#             echo -n "\"utc\":\"$(date -u -d "$DATE" +%F\ %T)\","
#             echo -n "\"year\":\"$(date -d "$DATE" +%Y)\","
#             echo -n "\"month\":\"$(date -d "$DATE" +%m)\","
#             echo -n "\"day\":\"$(date -d "$DATE" +%d)\","
#             echo -n "\"hour\":\"$(date -d "$DATE" +%H)\","
#             echo -n "\"minute\":\"$(date -d "$DATE" +%M)\","
#             echo -n "\"second\":\"$(date -d "$DATE" +%S)\""
#             echo -n "}"
#         } | jq .
#         unset DATE
#         return 0
#     }
#     formats() {
#         local DATETIME=${1:-"$(date +'%F %T')"}
#         {
#             echo -n "{"
#             echo -n "\"date\":\"$DATETIME\","
#             echo -n "\"timestamp\":\"$(date -d "$DATETIME" +%s)\","
#             echo -n "\"iso\":\"$(date -d "$DATETIME" --iso-8601=seconds)\","
#             echo -n "\"rfc3339\":\"$(date -d "$DATETIME" --rfc-3339=seconds)\""
#             echo -n "}"
#         } | jq .
#         unset DATETIME
#         return 0
#     }
#     now() {
#         timestamp() {
#             local timezone="${1:-UTC}"
#             if [ "$timezone" == "UTC" ]; then
#                 date -u +%s
#             else
#                 TZ=$timezone date -d "$(date -u +'%Y-%m-%d %H:%M:%S')" '+%s' # date +%s
#             fi
#         }
#         iso() {
#             local timezone="${1:-UTC}"
#             if [ "$timezone" == "UTC" ]; then
#                 local utc_seconds=$(date -u +%s)
#                 local utc_date=$(date -u -d @"$utc_seconds" +%Y-%m-%dT%H:%M:%S.%3NZ)
#                 echo "$utc_date"
#             else
#                 TZ=$timezone date +'%Y-%m-%dT%H:%M:%S.%3NZ' # date -u +"%Y-%m-%dT%H:%M:%S.%3NZ"
#             fi
#         }
#         __nnf "$@" || usage "dates" "$?" "$@" && return 1
#     }
#     diff() {
#         days() {
#             start=$(date -d "$1" +%s)
#             end=$(date -d "$2" +%s)
#             days_diff=$(((end - start) / 86400))
#             echo "$days_diff"
#         }
#         __nnf "$@" || usage "dates" "$?" "$@" && return 1
#     }
#     __nnf "$@" || usage "dates" "$?" "$@" && return 1
# }
# (
#     export -f dates
# )
