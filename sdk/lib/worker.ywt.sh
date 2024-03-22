#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2120,SC2155,SC2044
worker() {
    local ENGINES=("system" "container" "pod" )    
    __node(){
        if ! __is command node; then
            echo "Node is not installed" | logger from_buf error
            return 1
        fi
        node --quiet --experimental-repl-await "$@"
    }
    __npx(){
        if ! __is command npx; then
            echo "Npx is not installed" | logger from_buf error
            return 1
        fi
        npx --quiet --yes "$@"
    }
    __zx(){        
        __npx zx "$@"
    }
    __python(){
        if ! __is command python3; then
            echo "Python3 is not installed" | logger from_buf error
            return 1
        fi
        python3 "$@"
    }
    __go(){
        if ! __is command go; then
            echo "Go is not installed" | logger from_buf error
            return 1
        fi
        go run "$@"    
    }
    __docker(){
        if ! __is command docker; then
            echo "Docker is not installed" | logger from_buf error
            return 1
        fi
        docker "$@"    
    }
    __compose(){
        if ! __is command docker-compose; then
            echo "Docker-compose is not installed" | logger from_buf error
            return 1
        fi
        docker-compose "$@"    
    
    }
    __k8s(){
        if ! __is command kubectl; then
            echo "Kubectl is not installed" | logger from_buf error
            return 1
        fi
        kubectl "$@"    
    }
    __helm(){
        if ! __is command helm; then
            echo "Helm is not installed" | logger from_buf error
            return 1
        fi
        helm "$@"    
    }
    __terraform(){
        if ! __is command terraform; then
            echo "Terraform is not installed" | logger from_buf error
            return 1
        fi
        terraform "$@"    
    }    
} 
(
    export -f worker
)