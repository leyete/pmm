# [[[ OPTION PARSING

declare -g PMM_OP           # Operation
declare -g -A PMM_OPTS      # Command-line options
declare -g -a PMM_TARGETS   # Supplied targets
declare -g -a PMM_OPS PMM_SHORTOPTS PMM_LONGOPTS  # available command-line options

# global options.
PMM_OPS+=( h )
PMM_SHORTOPTS+=( v )
PMM_LONGOPTS+=( noconfirm verbose )

# opt-parse: Parses the command-line options.
function opt-parse() {
    local TEMP  # used to store the temporary environment.

    # zparseopts won't remove unknown options from the argument list if
    # they are in the same group as a known option (in the same '-').
    # for this reason, we will use getopt to expand all known options
    # so zparseopts will work as expected later.
    TEMP=$(getopt -o ${(j::)PMM_OPS}${(j::)${(u)PMM_SHORTOPTS}} -l ${(j:,:)${(u)PMM_LONGOPTS}} -n $PMM -- "$@")
    eval set -- "$TEMP"; unset TEMP

    # (1) parse the operation.
    opt-parse-op $@
    eval set -- "$TEMP"; unset TEMP

    [[ -z "$PMM_OP" && ${PMM_OPTS[help]} -eq 0 ]] && ERROR "an operation is required."
    (( ${PMM_OPTS[help]} )) && pmm-help  # this function does not return.

    # (2) parse operation-specific options.
    if (( $+functions[pmm-${PMM_OP}-parse-opt] )); then
        pmm-${PMM_OP}-parse-opt $@
        eval set -- "$TEMP"; unset TEMP
    fi

    # (3) parse global options.
    opt-parse-global $@
    eval set -- "$TEMP"; unset TEMP

    # (4) parse the supplied target strings.
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --) shift; break ;;  # end of options.
            *) ERROR "invalid option: $1." ;;
        esac
    done

    PMM_TARGETS=( ${(u)@} )
}

# opt-parse-op: Parses the current operation.
function opt-parse-op() {
    local options

    zparseopts -a options -E -D -- $PMM_OPS
    TEMP="$@"

    for option ( $options ); do
        case "$option" in
            -S) opt-set-op "sync" ;;
            -V) opt-set-op "version" ;;
            -h) PMM_OPTS[help]=1 ;;
        esac
    done
}

# opt-set-op: Sets the current operation.
function opt-set-op() {
    if [[ -n "$PMM_OP" ]]; then
        unset PMM_OP
        ERROR "only one operation may be used."
    fi
    PMM_OP="$1"
}

# opt-parse-global: Parses the global command-line options.
function opt-parse-global() {
    local options

    zparseopts -A options -D -E -- -noconfirm v -verbose
    TEMP="$@"

    opt-set-flag "noconfirm" "--noconfirm"
    opt-set-flag "verbose" "-v|--verbose"
}

# opt-set-flag: Sets the value of the supplied option based on the
#   presence of the supplied flags in the 'options' variable.
function opt-set-flag() {
    PMM_OPTS[$1]=${${(k)options[(i)$2]:+1}:-0}
}

# ]]]
