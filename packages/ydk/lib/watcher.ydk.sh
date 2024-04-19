#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:watcher() {
    ydk:try "$@"
    return $?
}

# watcher() {
#     dir() {
#         __require find md5sum sort cmp mv
#         WATCHED_DIR="/path/to/watched/dir"
#         SNAPSHOT="/var/tmp/dir_snapshot.txt"
#         TEMP_SNAPSHOT="/var/tmp/dir_snapshot_temp.txt"
# 
#         # Create a new snapshot
#         find "$WATCHED_DIR" -type f -exec md5sum {} + | sort >"$TEMP_SNAPSHOT"
# 
#         # Compare with the previous snapshot
#         if [ -f "$SNAPSHOT" ]; then
#             if ! cmp -s "$SNAPSHOT" "$TEMP_SNAPSHOT"; then
#                 echo "Change detected in $WATCHED_DIR at $(date)"
#                 # Take action here, such as restarting a service or sending a notification
# 
#                 # Update the snapshot for next comparison
#                 mv "$TEMP_SNAPSHOT" "$SNAPSHOT"
#             fi
#         else
#             echo "Initial snapshot of $WATCHED_DIR taken at $(date)"
#             mv "$TEMP_SNAPSHOT" "$SNAPSHOT"
#         fi
#     }
#     __nnf "$@" || usage "watcher" "$?"  "$@" && return 1
# 
# }
# (
#     export -f watcher
# )
