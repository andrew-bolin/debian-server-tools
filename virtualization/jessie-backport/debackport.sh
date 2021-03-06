#!/bin/bash
#
# Backport a Debian package.
#
# DOCKER        :szepeviktor/jessie-backport
# VERSION       :0.2.1
# REFS          :http://backports.debian.org/Contribute/#index6h3
# DOCS          :https://wiki.debian.org/SimpleBackportCreation

# A) Build from source package name/release codename
#
# Get source package name:
#     apt-get source --dry-run $PACKAGE|grep "^Fetch source"
#
# B) Build from .dsc file URL
#
# Get the .dsc file at
#     https://www.debian.org/distrib/packages#search_packages
#
# Hooks
#
# 1. init - Before everything else
# 2. source - Provide custom source, should cd to source directory and set CHANGELOG_MSG
# 3. pre-deps - Just before dependency installation
# 4. changes - Custom changelog entry
# 5. post-build - After build
#
# Package versioning
#     ${UPSTREAM_VERSION}[-${DEBIAN_REVISION}]~bpo${DEBIAN_RELEASE}+${BUILD_INT}

set -e

export DEBEMAIL="Viktor Szépe <viktor@szepe.net>"

ARCHIVE_URL="http://ftp.hu.debian.org/debian"
#ARCHIVE_URL="http://archive.ubuntu.com/ubuntu/"

ALLOW_UNAUTH="--allow-unauthenticated"

Error() {
    local RET="$1"

    shift
    echo "ERROR: $*" 1>&2
    exit "$RET"
}

Execute_hook() {
    local HOOK="debackport-$1"

    if ! [ -r "/opt/results/${HOOK}" ]; then
        return 0
    fi

    if source "/opt/results/${HOOK}"; then
        return 0
    else
        echo "HOOK ${HOOK} error: $?" 1>&2
        return 1
    fi
}

if [ -z "$PACKAGE" ]; then
    Error 1 'Usage:  docker run --rm --tty --volume /opt/results:/opt/results --env PACKAGE="openssl/testing" szepeviktor/jessie-backport'
fi

# Only for amd64
[ "$(uname -m)" == "x86_64" ] || Error 2 "Tested only on amd64"

CURRENT_RELEASE="$(lsb_release -s --codename)"

# Hook: init (e.g. set -x)
Execute_hook init

# Install .deb dependencies
sudo dpkg -R -i /opt/results/ || true
sudo apt-get update -qq
sudo apt-get install -y -f

if [ "${PACKAGE%.dsc}" != "$PACKAGE" ]; then
    # From .dsc URL
    dget --extract ${ALLOW_UNAUTH} "$PACKAGE"
    cd "$(basename "$PACKAGE" | cut -d "_" -f 1)-"*
    CHANGELOG_MSG="Built from DSC file: ${PACKAGE}"
elif [ "${PACKAGE//[^\/]/}" == "/" ]; then
    # From source "package name/release codename"
    RELEASE="${PACKAGE#*/}"
    {
        echo "deb-src ${ARCHIVE_URL} ${RELEASE} main"
        wget -q --spider "${ARCHIVE_URL}/dists/${RELEASE}-updates/" \
            && echo "deb-src ${ARCHIVE_URL} ${RELEASE}-updates main"
    } | sudo tee -a /etc/apt/sources.list
    sudo apt-get update -qq
    apt-get source "$PACKAGE"
    # "dpkg-source: info: extracting pkg in pkg-1.0.0"
    cd "${PACKAGE%/*}-"*
    CHANGELOG_MSG="Built from ${PACKAGE}"
else
    # From a custom source
    # Should cd to source directory and set CHANGELOG_MSG
    Execute_hook source
    if ! [ -d "debian" ]; then
        Error 3 "Custom source not available"
    fi
fi

# Hook: pre-deps (e.g. install dependencies from backports)
Execute_hook pre-deps

# Remove version number constraints and alternatives
DEPENDENCIES="$(dpkg-checkbuilddeps 2>&1 \
    | sed -e 's/^.*Unmet build dependencies: //' -e 's/ ([^)]\+)//g' -e 's/\(\S\+\)\( | \S\+\)\+/\1/g')"
if [ -n "$DEPENDENCIES" ]; then
    sudo apt-get install -y ${DEPENDENCIES}
fi

# Double check
dpkg-checkbuilddeps

# Hook: changes (e.g. dch --edit, edit files, debcommit --message $TEXT --all)
ORIG_HASH="$(md5sum debian/changelog)"
if ! Execute_hook changes || echo "$ORIG_HASH" | md5sum --status -c - ; then
    dch --bpo --distribution "${CURRENT_RELEASE}-backports" "$CHANGELOG_MSG"
fi

dpkg-buildpackage -us -uc

# Hook: post-build (e.g. sign and upload)
Execute_hook post-build

cd ../
#lintian --info
lintian --display-info --display-experimental --pedantic --show-overrides ./*.deb || true
sudo cp -av ./*.deb /opt/results/
echo "OK."
