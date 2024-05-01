#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:team() {
    local YDK_LOGGER_CONTEXT="team"
    release() {
        local YDK_OUTPUT=$({
            echo -n "{"
            echo -n "   \"id\": \"$(git rev-parse --short HEAD 2>/dev/null || echo "Unknown")\","
            echo -n "   \"hash\": \"$(git rev-parse HEAD 2>/dev/null || echo "Unknown")\","
            echo -n "   \"branch\": \"$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "Unknown")\","
            echo -n "   \"tag\": \"$(git describe --tags 2>/dev/null || echo "Unknown")\","
            # echo -n "   \"author\": \"$(git log -1 --pretty=format:'%an <%ae>' 2>/dev/null || echo "Unknown")\","
            echo -n "   \"message\": \"$(git log -1 --pretty=format:'%s' 2>/dev/null || echo "Unknown")\""
            echo -n "}"
        })
        # ydk:log success "$(jq -rc '.id + " SDK " + .tag + " | " + .message' <<<"$YDK_OUTPUT" 2>/dev/null)"
        echo "$YDK_OUTPUT" >&4
        return 0
    }
    info() {
        local YDK_OUTPUT=$({
            echo -n "{"
            echo -n "\"license\": \"MIT\","
            echo -n "\"repo\": {"
            echo -n "\"owner\": \"$YDK_OWNER\","
            echo -n "\"name\": \"$YDK_REPO\","
            echo -n "\"branch\": \"$YDK_BRANCH\","
            echo -n "\"version\": \"$YDK_VERSION\","
            echo -n "\"api\": \"https://api.github.com/repos/$YDK_OWNER/$YDK_REPO\","
            echo -n "\"raw\": \"https://raw.githubusercontent.com/$YDK_OWNER/$YDK_REPO/$YDK_BRANCH\","
            echo -n "\"homepage\": \"${YDK_LINKS[homepage]}\""
            echo -n "},"
            echo -n "\"info\": {"
            echo -n "\"team\": \"${YDK_INFO[team]}\","
            echo -n "\"name\": \"${YDK_INFO[name]}\","
            echo -n "\"version\": \"${YDK_INFO[version]}\","
            echo -n "\"description\": \"${YDK_INFO[description]}\""
            echo -n "},"
            echo -n "\"author\": {"
            echo -n "\"name\": \"${YDK_AUTHOR[name]}\","
            echo -n "\"email\": \"${YDK_AUTHOR[email]}\","
            echo -n "\"uri\": \"${YDK_AUTHOR[uri]}\""
            echo -n "},"
            echo -n "\"build\": {"
            echo -n "   \"name\": \"ydk-shell\","
            echo -n "   \"date\": \"$(date -Iseconds)\""
            echo -n "},"
            echo -n "\"release\": {"
            echo -n "   \"name\": \"ydk-shell\","
            echo -n "   \"date\": \"$(date -Iseconds)\""
            echo -n "}"
            echo -n "}"
        })

        echo "$YDK_OUTPUT" >&4
        return 0
    }
    welcome() {
        local YDK_TEAM_INFO=$(info 4>&1)
        ydk:logger success "$(jq -rc '.info.team + " | " + .info.name + " | " + .info.description + " | " + .info.homepage' <<<"$YDK_TEAM_INFO" 2>/dev/null)"
        ydk:logger info "Need a help? Visit ${YDK_LINKS[docs]} :book:"
        return 0
        # local YWT_PACKAGE=$(package)
        # local NAME && NAME=$(jq -r '.name' <<<"$YWT_PACKAGE") && readonly NAME
        # local VERSION && VERSION=$(jq -r '.version' <<<"$YWT_PACKAGE") && readonly VERSION
        # local DESCRITPTION=$(jq -r '.description' <<<"$YWT_PACKAGE")
        # local URI && URI=$(jq -r '.homepage' <<<"$YWT_PACKAGE") && readonly URI
        # colors hyperlink "$URI" "$(colors apply "yellow" "${NAME}@${VERSION} | ${DESCRITPTION} | $URI")" | logger info
        # "Yellow Team"
        # ?utm_source=yellowteam&utm_medium=cli&utm_campaign=yellowteam
    }
    copyright() {
        local YDK_TEAM_INFO=$(info 4>&1)
        local YDK_RELEASE_INFO=$(release 4>&1)
        # local YDK_TEAM_INFO={} YDK_RELEASE_INFO={}
        # info && read -r -u 4 YDK_TEAM_INFO || return $?
        # release && read -r -u 4 YDK_RELEASE_INFO || return $?
        echo "# YELLOW TEAM BUNDLE"
        echo "# $(jq -c .info <<<"$YDK_TEAM_INFO")"
        echo "# This file is generated by yellowteam sdk builder. Do not edit this file"
        echo "# Build date: $(date -Iseconds)"
        echo "# Build ID: $(jq -r .id <<<"$YDK_RELEASE_INFO")"
        echo "# Build branch: $(jq -r .branch <<<"$YDK_RELEASE_INFO")"
        echo "# Build tag: $(jq -r .tag <<<"$YDK_RELEASE_INFO")"
        echo "# Build commit: $(jq -r .hash <<<"$YDK_RELEASE_INFO")"
        echo "# Build message: $(jq -r .message <<<"$YDK_RELEASE_INFO")"
        return 0
    }
    ydk:try "$@" 4>&1
    return $?
}
{
    [[ -z "$YDK_OWNER" ]] && export YDK_OWNER="ywteam" # "cloudyellowteam"
    [[ -z "$YDK_REPO" ]] && export YDK_REPO="ydk-shell" && readonly YDK_REPO
    [[ -z "$YDK_BRANCH" ]] && export YDK_BRANCH="main" && readonly YDK_BRANCH
    [[ -z "$YDK_VERSION" ]] && export YDK_VERSION="0.0.0-dev-0"
    [[ -z "$YDK_LINKS" ]] && declare -g -A YDK_LINKS=(
        ["homepage"]="https://yellowteam.cloud"
        ["api"]="https://api.github.com/repos/${YDK_OWNER}/${YDK_REPO}"
        ["raw"]="https://raw.githubusercontent.com/${YDK_OWNER}/${YDK_REPO}/${YDK_BRANCH}"
        ["bugs"]="https://bugs.yellowteam.cloud"
        ["docs"]="https://docs.yellowteam.cloud"
        ["wiki"]="https://wiki.yellowteam.cloud"
        ["chat"]="https://chat.yellowteam.cloud"
        ["forum"]="https://forum.yellowteam.cloud"
        ["store"]="https://store.yellowteam.cloud"

    ) && readonly YDK_LINKS
    [[ -z "$YDK_INFO" ]] && declare -g -A YDK_INFO=(
        ["team"]="@ywteam"
        ["name"]="https://yellowteam.cloud/ydk-shell"
        ["version"]="$YDK_VERSION"
        ["description"]="shell SDK"
    ) && readonly YDK_INFO
    [[ -z "$YDK_AUTHOR" ]] && declare -g -A YDK_AUTHOR=(
        ["name"]="Raphael Rego"
        ["email"]="hello@raphaelcarlosr.dev"
        ["homepage"]="https://raphaelcarlosr.dev"
    ) && readonly YDK_AUTHOR
}
