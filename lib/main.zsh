# [[[ MAIN

# program flow starts here <---

if [[ "$UID" -eq 0 ]]; then
    echo ":: Do not run this script as root!"
    if [[ -n "$SUDO_USER" ]]; then
        echo ":: Downgrading credentials to '$SUDO_USER'."
        exec sudo -u "$SUDO_USER" $0 $*
    fi

    exit 1
fi

(( $# )) || pmm-help
pmm-set-env && log-init "$@" && opt-parse "$@" && pmm-${PMM_OP} || exit 1

# ]]]
