#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:vault() {
    ydk:try "$@" 4>&1
    return $?
}

# vault() {
#     check() {
#         # Check if URL was provided
#         if [ "$#" -ne 1 ]; then
#             echo "Usage: $0 <URL>"
#             exit 1
#         fi
# 
#         # The webpage URL
#         URL="$1"
# 
#         # Directory to save the JavaScript files
#         DOWNLOAD_DIR="./js_files"
#         mkdir -p "$DOWNLOAD_DIR"
# 
#         # Fetch the HTML content of the page
#         HTML_CONTENT=$(curl -s "$URL")
# 
#         # Extract the JavaScript file links
#         echo "$HTML_CONTENT" | grep -oE '<script src="([^"]+)"' | cut -d'"' -f2 | sort -u | while read -r JS_PATH; do
#             # Handle both absolute and relative URLs
#             if [[ "$JS_PATH" == http* ]]; then
#                 JS_URL="$JS_PATH"
#             else
#                 JS_URL=$(echo "$URL" | sed 's|/[^/]*$|/|')"$JS_PATH"
#             fi
# 
#             # Filename for saving
#             FILENAME=$(basename "$JS_PATH")
#             FILEPATH="$DOWNLOAD_DIR/$FILENAME"
# 
#             # Download the JavaScript file
#             echo "Downloading $JS_URL to $FILEPATH"
#             curl -s "$JS_URL" -o "$FILEPATH"
#         done
#     }
#     __nnf "$@" || usage "vault" "$?"  "$@" && return 1
# 
# }
# (
#     export -f vault
# )
