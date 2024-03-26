#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2120,SC2155,SC2044
scan() {
    local ARGS=()
    local PARAMS="{"
    while [ "$#" -gt 0 ]; do
        case "$1" in
        --port)
            PARAMS+="\"port\": \"$2\","
            shift 2
            ;;
        --domain)
            PARAMS+="\"domain\": \"$2\","
            shift 2
            ;;
        --ip)
            PARAMS+="\"ip\": \"$2\","
            shift 2
            ;;
        --url)
            PARAMS+="\"url\": \"$2\","
            shift 2
            ;;
        --host)
            PARAMS+="\"host\": \"$2\","
            shift 2
            ;;
        --email)
            PARAMS+="\"email\": \"$2\","
            shift 2
            ;;
        --phone)
            PARAMS+="\"phone\": \"$2\","
            shift 2
            ;;
        --repository)
            PARAMS+="\"repository\": \"$2\","
            shift 2
            ;;
        --docker:image)
            PARAMS+="\"docker:image\": \"$2\","
            shift 2
            ;;
        --docker:container)
            PARAMS+="\"docker:container\": \"$2\","
            shift 2
            ;;
        --docker:registry)
            PARAMS+="\"docker:registry\": \"$2\","
            shift 2
            ;;
        --company)
            PARAMS+="\"company\": \"$2\","
            shift 2
            ;;
        --npm:package)
            PARAMS+="\"npm:package\": \"$2\","
            shift 2
            ;;
        --npm:module)
            PARAMS+="\"npm:module\": \"$2\","
            shift 2
            ;;
        --npm:registry)
            PARAMS+="\"npm:registry\": \"$2\","
            shift 2
            ;;
        --npm:scope)
            PARAMS+="\"npm:scope\": \"$2\","
            shift 2
            ;;
        --npm:token)
            PARAMS+="\"npm:token\": \"$2\","
            shift 2
            ;;
        --npm:user)
            PARAMS+="\"npm:user\": \"$2\","
            shift 2
            ;;
        *)
            ARGS+=( "$1" )
            shift
            ;;
        esac
    done
    PARAMS="${PARAMS%,}"
    PARAMS+="}"
    echo "${PARAMS}" | jq .
    set -- "${ARGS[@]}" && unset ARGS
    return 0

    port() {
        echo "port"
    }
    domain() {
        echo "domain"
    }
    ip() {
        echo "ip"
    }
    url() {
        echo "url"
    }
    host() {
        echo "host"
    }
    email() {
        echo "email"
    }
    phone() {
        echo "phone"
    }
    repository() {
        echo "repository"
    }
    docker:image() {
        echo "docker:image"
    }
    docker:container() {
        echo "docker:container"
    }
    docker:registry() {
        echo "docker:network"
    }
    __nnf "$@" || usage "tests" "$?" "$@" && return 1
}
(
    export -f scan
)
