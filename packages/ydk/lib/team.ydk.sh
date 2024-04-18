#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:team() {
    local YDK_LOGGER_CONTEXT="team"
    version() {
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
        ydk:logger success "$(jq -rc '.id + " SDK " + .tag + " | " + .message' <<<"$YDK_OUTPUT" 2>/dev/null)"
        echo "$YDK_OUTPUT" >&4
        return 0
    }
    info() {
        ydk:logger info "Do you want contribute to this project? Please visit ${YDK_LINKS[homepage]}"
        local YDK_OUTPUT=$({
            echo -n "{"
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
            echo -n "}"
            echo -n "}"
        })
        ydk:logger success "$(jq -rc '.info.team + " SDK " + .info.version + " | " + .info.name + " | " + .info.description' <<<"$YDK_OUTPUT" 2>/dev/null)"
        echo "$YDK_OUTPUT" >&4
        return 0
    }
    ydk:try "$@"
    return $?
}
{
    [[ -z "$YDK_OWNER" ]] && export YDK_OWNER="ywteam" # "cloudyellowteam"
    [[ -z "$YDK_REPO" ]] && export YDK_REPO="ydk-shell" && readonly YDK_REPO
    [[ -z "$YDK_BRANCH" ]] && export YDK_BRANCH="main" && readonly YDK_BRANCH
    [[ -z "$YDK_VERSION" ]] && export YDK_VERSION="0.0.0-dev-0"
    [[ -z "$YDK_LINKS" ]] && declare -g -A YDK_LINKS=(
        ["api"]="https://api.github.com/repos/${YDK_OWNER}/${YDK_REPO}"
        ["raw"]="https://raw.githubusercontent.com/${YDK_OWNER}/${YDK_REPO}/${YDK_BRANCH}"
        ["bugs"]="https://bugs.yellowteam.cloud"
        ["homepage"]="https://yellowteam.cloud"
    ) && readonly YDK_LINKS
    [[ -z "$YDK_INFO" ]] && declare -g -A YDK_INFO=(
        ["team"]="@ywteam"
        ["name"]="Yellow Team SDK"
        ["version"]="$YDK_VERSION"
        ["description"]="Cloud Yellow Team | Shell SDK"
    ) && readonly YDK_INFO
    [[ -z "$YDK_AUTHOR" ]] && declare -g -A YDK_AUTHOR=(
        ["name"]="Raphael Rego"
        ["email"]="hello@raphaelcarlosr.dev"
        ["homepage"]="https://raphaelcarlosr.dev"
    ) && readonly YDK_AUTHOR
}
