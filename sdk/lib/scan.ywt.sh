#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2120,SC2155,SC2044
scan() {
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
