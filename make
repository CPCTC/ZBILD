#!/bin/bash
set -eu
here=$(dirname $0); (exit $?)

defaults() {
    build=.build
    cache=.cache

    name=app
    do=build-exe
    flag -lc
    flag -O Debug
    main="$here/src/main.zig"
}

declare -a flags=()
flag() {
    while (($#)); do
        flags[${#flags[@]}]="$1"
        shift
    done
}

declare -A strs=()
str() {
    local name="$1"; shift

    var "$name"
    strs["$name"]=y
}

declare -a vars=()
declare -A var_types=()
var() {
    local name="$1"; shift

    vars[${#vars[@]}]="$name"

    if (($#)); then
        local type="$1"; shift
        var_types["$name"]="$type"
    fi
}

declare -a switches=()
switch() {
    local name="${1,*}"; shift

    switches[${#switches[@]}]="$name"
    local opt_name="switch_${name}_opts"
    declare -ga "$opt_name=()"
    local -n opts="$opt_name"
    local o
    for o in "$@"; do
        opts[${#opts[@]}]="$o"
    done
}

gen_config() {
    local var
    for var in "${vars[@]}"; do
        local -n val="$var"
        echo -n "pub const $var"
        if [[ -v var_types["$var"] ]]; then
            echo -n ": ${var_types["$var"]}"
        fi
        echo -n " = "
        if [[ -v strs["$var"] ]]; then
            echo -n "\"$val\""
        else
            echo -n "$val"
        fi
        echo ';'
    done

    local switch
    for switch in "${switches[@]}"; do
        echo "pub const ${switch^*} = enum {"

        local -n opts="switch_${switch}_opts";
        local o
        for o in "${opts[@]}"; do
            echo "    $o,"
        done

        echo "};"

        local -n val="$switch"
        echo "pub const $switch = ${switch^*}.$val;"
    done
}

main() {
    defaults

    rm -rf "$build"
    mkdir -p "$build" "$cache"

    while (($#)); do
        if [[ $1 == '--' ]]; then
            shift
            flag "$@"
            break
        else
            eval "$1"
            shift
        fi
    done

    gen_config > "$build/config.zig"

    zig "$do" "${flags[@]}" --pkg-begin config "$build/config.zig" \
        --enable-cache --cache-dir "$cache" -femit-bin="$build/$name" "$main"
}

main "$@"
