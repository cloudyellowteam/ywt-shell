#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
vcs() {
    # Variables
    GITHUB_TOKEN=""
    OWNER="ywteam"
    REPO="devsecops.rest"
    SARIF_FILE="./sarif.json"     
    API_URL="https://api.github.com/repos/$OWNER/$REPO/code-scanning/sarifs"
    UPLOAD_ID=$(uuidgen)
    # API request
    curl -i -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "$API_URL" \
        -d @- <<EOF
{
  "commit_sha": "fcc15d285b415ce9f63f810b868b4119a139c41b",
  "ref": "refs/heads/main",
  "sarif": "$(gzip -c "$SARIF_FILE" | base64 -w0)",
  "checkout_uri": "https://github.com/$OWNER/$REPO",
  "started_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "tool_name": "ywt"
}
EOF

    exit 255
}
