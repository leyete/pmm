# [[[ HELPERS

# pmm-set-env: Sets the requried environment for a proper run.
function pmm-set-env() {
    declare -g PMM PMMHOME PMMCONF PMMLOGF PMMDIST PMMREPD

    # comply with the XDG Base Directory Specification
    export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
    export XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"

    PMM="${${(%):-%x}:A:t}"
    PMMHOME="${PMMHOME:-${XDG_DATA_HOME}/pmm}"
    PMMCONF="${PMMCONF:-${XDG_CONFIG_HOME}/pmm}"
    PMMREPD="${PMMREPD:-${PMMHOME}/repos}"
    PMMBIND="${PMMBIND:-${PMMHOME}/bin}"

    # make sure the required directories exist.
    for dir ( ${PMMHOME:A} ${PMMCONF:A} ${PMMREPD:A} ${PMMBIND:A} ); do
        [[ -d "$dir" ]] || { mkdir -p $dir || { echo "error: unable to create '$dir'"; return 1; } }
    done

    # set options and load requried modules.
    setopt EXTENDED_GLOB
    setopt ERR_RETURN
    setopt REMATCH_PCRE
    setopt PIPE_FAIL

    zmodload zsh/datetime  # timestamps
    zmodload zsh/terminfo  # terminfo capabilities
    zmodload zsh/pcre      # regular expressions pearl-style

    # set the current distribution.
    [[ -z "$PMMDIST" ]] && pmm-set-dist
}

# pmm-set-dist: Sets the current distribution from /etc/os-release.
#   Distribution is set in the PMMDIST environment variable.
function pmm-set-dist()
{
    declare -g PMMDIST
    local os_release os_release_id match mbegin mend MATCH MBEGIN MEND

    os_release="$(cat /etc/os-release 2>/dev/null)"
    [[ ${(f)os_release} =~ 'ID=([A-Za-z]+)' ]] && os_release_id="${match[1]}"

    case "$os_release_id" in
        *arch*)   PMMDIST="arch" ;;
        *ubuntu*) PMMDIST="ubuntu" ;;
        *parrot*) PMMDIST="parrot" ;;
        *kali*)   PMMDIST="kali" ;;
        *debian*) PMMDIST="debian" ;;
        *)        PMMDIST="$os_release_id" ;;
    esac

    if [[ -z "$PMMDIST" ]]; then
        echo "error: unable to set current distribution from /etc/os-release," \
            "you may need to set the PMMDIST variable with the correct value."
    fi
}

# pmm-help: Displays the requested help text. This function does not
#   return.
function pmm-help() {
    if [[ -n "$PMM_OP" ]] && (( $+functions[pmm-${PMM_OP}-help] )); then
        pmm-${PMM_OP}-help
    else
        cat <<EOH
usage: ${PMM:-${${(%):-%x}:A:t}} <operation> [options]

OPERATIONS:
    -S              Synchronize: Install/upgrade modules.
    -V              Version: Print current version banner and exit.
    -h              Help: Show usage message and exit.

OPTIONS:
    --noconfirm     Avoid user prompts. The script won't ask questions to the user,
                    this is useful if you want to use ${PMM:-${${(%):-%x}:A:t}} in scripts.
    --verbose       Show external commands' output.

Use '${PMM:-${${(%):-%x}:A:t}} -h' with an operation for extended help.
EOH
    fi

    exit 0
}

# ]]]
