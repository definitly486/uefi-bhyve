#!/bin/sh

# Использование:
# ./list_x86_dirs.sh install.wim [image_index]

WIM=$1
INDEX=${2:-1}

[ -n "$WIM" ] || {
    echo "Usage: $0 <install.wim> [image_index]"
    exit 1
}

wimdir "$WIM" "$INDEX" |
grep -E '^/?Windows/WinSxS/(x86_[^/]+/?$|Manifests/x86[^/]*)' |
sed -E "s#^/*(Windows/WinSxS/(x86_[^/]+|Manifests/x86[^/]*).*)#delete --recursive '\1'#" |
uniq