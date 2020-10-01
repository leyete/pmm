# [[[ LOGGING

PMM_WITH_DEBUG={{__PMM_WITH_DEBUG__}}

# log-init: Initializes the logging subsystem.
function log-init() {
    local timestamp=$EPOCHSECONDS

    # set the value for the log file if missing.
    PMMLOGF=${PMMLOGF:-"$PMMHOME/log/pmm-$(strftime "%d-%m-%y-%h%m%s").log"}
    [[ ! -d "${PMMLOGF:A:h}" ]] && mkdir -p "${PMMLOGF:A:h}"

    # append debug information.
    if [[ $PMM_WITH_DEBUG == true ]]; then
        cat >> "$PMMLOGF" <<EOF
# Personal Module Manager - version: {{__PMM_VERSION__}} - revision: {{__PMM_REVISION__}} ({{__PMM_REVISION_DATE__}})
# Session Started: $(strftime "%d/%m/%Y %H:%M:%S" $timestamp)
# Session Options: $*


EOF
    fi
}

function TRACE() {
    [[ $PMM_WITH_DEBUG == false ]] && return

    local timestamp="$(strftime "%H:%M:%S %d/%m/%Y" $EPOCHSECONDS)"
    print "$timestamp :: ${functrace[1]} :: $*" >> $PMMLOGF
}

function INFO() {
    print -P ":: ${PMM_OP:+"%F{magenta}${PMM_OP}%f :: "}$*"
}

function WARN() {
    print -P ":: %B%F{yellow}WARN%f%b :: ${PMM_OP:+"%F{magenta}${PMM_OP}%f :: "}$*"
}

function ERROR() {
    local timestamp="$(strftime "%H:%M:%S %d/%m/%Y" $EPOCHSECONDS)"
    print -P ":: %B%F{red}ERROR%f%b :: ${PMM_OP:+"%F{magenta}$PMM_OP%f :: "}$*" >&2
    print "$timestamp :: ERROR :: ${functrace[1]} :: $*" >> $PMMLOGF
    return 1
}

# ]]]
