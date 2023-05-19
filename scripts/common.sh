#!/usr/bin/env bash
# shellcheck disable=SC2034

msg() {
    fmt="$1"
    if [ $# -gt 1 ]; then
        shift
    fi
    # shellcheck disable=SC2059
    printf "$fmt\n" "$@" >&2
}

msg_verbose() {
    if [ "${verbose:-0}" -ge "1" ]; then
        msg "$@"
    fi
}

msg_debug() {
    if [ "${verbose:-0}" -ge "2" ]; then
        msg "$@"
    fi
}

die() {
    msg "$@"
    exit 1
}

has() {
    command -v "$1" >/dev/null 2>&1
}

printcmd() {
    python3 -c 'import subprocess,sys; print(subprocess.list2cmdline(sys.argv[1:]))' "$@"
}

run() {
    if [ "${verbose:-0}" -gt 0 ]; then
        printf '❯ %s\n' "$(printcmd "$@")" >&2
    fi
    if [ -z "${dry_run:-}" ]; then
        "$@"
    fi
}

filter() {
    if [ -n "$include" ]; then
        grep -E "$include"
    else
        cat
    fi |
        if [ -n "$exclude" ]; then
            grep -Ev "$exclude"
        else
            cat
        fi
}

quote(){
    sed -e "s,','\\\\'',g; 1s,^,',; \$s,\$,',;" << EOF
$1
EOF
}

# Via https://stackoverflow.com/a/4622512
read_tdf_line() {
    local default_ifs=$' \t\n'
    local n line element at_end old_ifs
    old_ifs="${IFS:-${default_ifs}}"
    IFS=$'\n'

    if ! read -r line ; then
        return 1
    fi
    at_end=0
    while read -r element; do
        if (( $# > 1 )); then
            printf -v "$1" '%s' "$element"
            shift
        else
            if (( at_end )) ; then
                # replicate read behavior of assigning all excess content
                # to the last variable given on the command line
                printf -v "$1" '%s\t%s' "${!1}" "$element"
            else
                printf -v "$1" '%s' "$element"
                at_end=1
            fi
        fi
    done < <(tr '\t' '\n' <<<"$line")

    # if other arguments exist on the end of the line after all
    # input has been eaten, they need to be blanked
    if ! (( at_end )) ; then
        while (( $# )) ; do
            printf -v "$1" '%s' ''
            shift
        done
    fi

    # reset IFS to its original value (or the default, if it was
    # formerly unset)
    IFS="$old_ifs"
}

abspath() {
    _path="$1"
    if [ -n "${_path##/*}" ]; then
        _path="${2:-$PWD}/$1"
    fi
    echo "$_path"
}

abs_readlink() {
    for arg; do
        abspath "$(readlink "$arg")" "$(dirname "$arg")"
    done
}

mcd () {
    # shellcheck disable=SC2164
    mkdir -p "$1" && cd "$1"
}

common_usage() {
    echo >&2 "${0##*/} [options] [ARGS..]"
    echo >&2
    echo >&2 "Common Options:"
    echo >&2
    echo >&2 "  -u                 Update mirror."
    echo >&2 "  -c DIRECTORY     Change to DIRECTORY before mirroring."
    echo >&2 "  -a ARGS           Change default underlying tool arguments."
    exit 2
}

usage () {
    common_usage
}

common_process_arguments() {
    update=
    directory=
    while getopts uc:a:h opt; do
        case "$opt" in
        u)
            update=1
            ;;
        c)
            directory="$OPTARG"
            ;;
        a)
            ARGS="$OPTARG"
            ;;
        \? | h)
            usage
            ;;
        esac
    done
    shift $((OPTIND - 1))
}

process_arguments() {
    common_process_arguments "$@"
}
