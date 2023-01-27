#!/bin/bash
set -e
here=$(dirname $0); (exit $?)

name='app'
target='build-exe'
flags+='-lc '
flags+='-O Debug '

main="$here/src/main.zig"

# End Config

build=.build
cache=.cache
eval "$@"
rm -rf "$build"
mkdir -p "$build" "$cache"
zig "$target" $flags --enable-cache --cache-dir "$cache" -femit-bin="$build/$name" "$main"
