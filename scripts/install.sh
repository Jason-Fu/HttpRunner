#!/bin/bash
# install hrp with one shell command
# bash -c "$(curl -ksSL https://httprunner.com/script/install.sh)"

set -e

function echoError() {
    echo -e "\033[31m✘ $1\033[0m" # red
}
export -f echoError

function echoInfo() {
    echo -e "\033[32m✔ $1\033[0m" # green
}
export -f echoInfo

function echoWarn() {
    echo -e "\033[33m! $1\033[0m" # yellow
}
export -f echoError

function get_latest_version() {
    curl -ksSL https://httprunner.oss-cn-beijing.aliyuncs.com/VERSION
}

function get_os() {
    os=$(uname -s)
    echo "$os" | tr '[:upper:]' '[:lower:]'
}

function get_arch() {
    arch=$(uname -m)
    if [ "$arch" == "x86_64" ]; then
        arch="amd64"
    fi
    echo "$arch"
}

function get_pkg_suffix() {
    os=$1
    if [ "$os" == "windows" ]; then
        echo ".zip"
    else
        echo ".tar.gz"
    fi
}

function extract_pkg() {
    pkg=$1
    if [[ $pkg == *.zip ]]; then # windows
        echo "$ unzip -o $pkg -d ."
        unzip -o $pkg -d .
    else
        echo "$ tar -xzf $pkg"
        tar -xzf "$pkg"
    fi
}

function main() {
    echoInfo "Detect target hrp package..."
    version=$(get_latest_version)
    if [[ $version != v* ]]; then
        echo "get hrp latest version failed:"
        echo "$version"
        exit 1
    fi

    os=$(get_os)
    echo "Current OS: $os"
    arch=$(get_arch)
    echo "Current ARCH: $arch"
    pkg_suffix=$(get_pkg_suffix $os)
    pkg="hrp-$version-$os-$arch$pkg_suffix"

    # download from aliyun OSS
    url="https://httprunner.oss-cn-beijing.aliyuncs.com/$pkg"
    if ! curl --output /dev/null --silent --head --fail "$url"; then
        # aliyun OSS url is invalid, try to download from github
        version=$(get_latest_version)
        pkg="hrp-$version-$os-$arch$pkg_suffix"
        url="https://github.com/httprunner/httprunner/releases/download/$version/$pkg"
    fi

    echo "Latest version: $version"
    echo "Download url: $url"
    echo

    echoInfo "Created temp dir..."
    echo "$ mktemp -d -t hrp.XXXX"
    tmp_dir=$(mktemp -d -t hrp.XXXX)
    echo "$tmp_dir"
    cd "$tmp_dir"
    echo

    echoInfo "Downloading..."
    echo "$ curl -kL $url -o $pkg"
    curl -kL $url -o "$pkg"
    echo

    echoInfo "Extracting..."
    extract_pkg "$pkg"
    echo "$ ls -lh"
    ls -lh
    echo

    echoInfo "Installing..."
    if hrp -v > /dev/null && [ $(command -v hrp) != "./hrp" ]; then
        echoWarn "$(hrp -v) exists, remove first !!!"
        echo "$ rm -rf $(command -v hrp)"
        rm -rf "$(command -v hrp)"
    fi

    echo "$ chmod +x hrp && mv hrp /usr/local/bin/"
    chmod +x hrp
    mv hrp /usr/local/bin/
    echo

    echoInfo "Check installation..."
    echo "$ command -v hrp"
    command -v hrp
    echo "$ hrp -v"
    hrp -v
    echo "$ hrp -h"
    hrp -h
}

main
