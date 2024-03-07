#!/usr/bin/env sh
set -e

export BATS_VERSION # version/git tag to use
export SUCCESS=0

ensure() {
    packages="$*"
    echo "Ensure availability of: $packages "
    ROOT_USER_ID=0
    [ "$(id -u)" -ne $ROOT_USER_ID ] && privileges="sudo "

    type apk >/dev/null 2>&1 && echo 'Alpine' &&
        "$privileges"apk add \
            --no-cache \
            $packages
    type apt >/dev/null 2>&1 && echo 'Debian/Ubuntu' &&
        "$privileges"apt-get update &&
        "$privileges"apt-get install \
            --yes \
            --no-install-recommends \
            $packages &&
        "$privileges"rm -rf /var/lib/apt/lists/*
    type dnf >/dev/null 2>&1 && echo 'RockyLinux/Centos/Fedora' &&
        dnf upgrade-minimal \
            --assumeyes &&
        dnf install \
            --assumeyes \
            $packages &&
        dnf clean all

    echo "Ensure… done"
}

set_version_to_use() {
    VERSION=${VERSION:-"latest"}

    if [ "$VERSION" = 'latest' ]; then
        echo "master"
        exit "$SUCCESS"
    fi
    echo "$VERSION"
}

install_bats() {
    GIT_TAG=${1:-master}
    CLONE_DIR=${2:-$_REMOTE_USER_HOME}

    echo "Cloning bats-core"

    git clone https://github.com/bats-core/bats-core.git \
        --branch "$GIT_TAG" \
        "$CLONE_DIR/bats-core" &&
        cd "$CLONE_DIR/bats-core" &&
        ./install.sh "$_REMOTE_USER_HOME"
}

add_bats_to_PATH() {
    export PATH="${_REMOTE_USER_HOME}/bin:$PATH"
    echo 'export PATH="$HOME/bin:$PATH"' >>${_REMOTE_USER_HOME}/.bashrc
    echo 'export PATH="$HOME/bin:$PATH"' >>${_REMOTE_USER_HOME}/.profile
}

run() {
    . "$(dirname "$0")"/ensure.sh && ensure 'git ca-certificates wget bash'

    echo "Installing… Bats (Bash Automated Testing System)"
    echo "User: ${_REMOTE_USER}     User home: ${_REMOTE_USER_HOME}"

    BATS_VERSION=$(set_version_to_use)
    echo "The provided Bats version is: $BATS_VERSION"

    install_bats "$BATS_VERSION"
    add_bats_to_PATH
}

run
