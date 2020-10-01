# [[[ TARGET

# target-expand: Expands the target string. The result is stored in
#   the RESULT variable:
#   - [module] : module uri (<user>/<repo>[@repo]/<module>).
#   - [targets]: comma-separated list of targets. 
function target-expand() {
    local target="${1%:*}" selection=1 match mbegin mend MATCH MBEGIN MEND
    declare -a matches

    # this regular expression matches all possible target specifications.
    if [[ "$target" =~ '^(([A-Za-z\-\d]+)/)?(([A-Za-z\-\d]+(@(.*))?)/)?[A-Za-z\-\d]+$' ]]; then
        if [[ -n "${match[2]}" && -n "${match[4]}" ]]; then
            RESULT[module]="$target"
            RESULT[targets]="${1##*:}"

            # full target string specified, no further action required.
            return 0
        fi

        # partial target string specified, expand string to match any
        # installed repositories.
        # insert a wildcard (*) in any missing element of the string.
        cd $PMMREPD
        matches=( ${${match[2]:+${match[4]:+${match[2]}}}:-*}/${match[4]:-${match[2]:-*}}/${target##/*}(N) )
        cd -
    else
        ERROR "invalid target string."
    fi

    TRACE "partial target string '$target' matches:\n\t${(j/\n\t/)${(s/,/)matches}}"

    case "${#matches}" in
        0)  ERROR "unable to locate target '$1'." ;;
        *)  [[ ${#matches} -gt 1 ]] && util-select-from "ambiguous target string, select one from the list:" $matches ;;
    esac

    RESULT[module]="${matches[$selection]}"
    RESULT[targets]="${1##*:}"
}

# target-installed: Checks whether or not the supplied target is
#   already installed. Ment for tool-install targets.
function target-installed() {
    grep -q -E "^$1 | $2 | .*\$" "$PMMHOME/pmm.db" 2>/dev/null
}

# target-validate: Makes sure the supplied target is valid.
function target-validate() {
    local module="$1" target="$2" target_path="$PMMREPD/$1/$2"

    [[ ! -d "$target_path" ]] && ERROR "target '$module:$target' not found."

    if [[ ! -f "$target_path/target.zsh" && ! -f "$target_path/target.link" ]]; then
        ERROR "target '$module:$target': unspecified target file."
    fi
}

# target-install: Installs the supplied target.
function target-install() {
    local module="$1" target="$2" t_path="$PMMREPD/$1/$2" installed
    local match mbegin mend MATCH MBEGIN MEND
    
    if [[ -f "$t_path/target.zsh" ]]; then
        target-installed "$module" "$target" && installed=true || intalled=false

        if [[ "$installed" == true ]]; then
            (( ${PMM_OPTS[upgrade]} )) && { -target-upgrade; return; }
            util-ask-boolean "$module:$target is alredy installed, reinstall it?" || return 0
        fi

        -target-install "$installed"
    else
        # this target links files.
        for line ( ${(f)"$(< $t_path/target.link)"} ); do
            [[ "$line" =~ "^${PMM_OPTS[host]} \| (.*)+ \| (.*)+\$" ]] || continue
            -target-link "${match[1]}" "${match[2]}" || continue
        done
    fi
}

# -target-install: Installs the target available on the variable
#   $target ( from the module $module ). If "true" is supplied to
#   this function, the module will be reinstalled.
function -target-install() {
    local t_path="$PMMREPD/$module/$target" reinstall="$1" install_func

    [[ ! -f "$t_path/target.zsh" ]] && ERROR "missing 'target.zsh' file (target: $module:$target)."
    [[ ! -r "$t_path/target.zsh" ]] && ERROR "target.zsh: permission denied (target: $module:$target)."

    (  # subshell to avoid environment clashes.
        declare -A TARGET
        cd "$t_path"
        source "./target.zsh"

        install_func="$(target-get-func install $PMMDIST)"
        [[ -z "$install_func" ]] && { WARN "skipping target $module:$target (no install function)."; return 0; }

        if [[ "$reinstall" == true ]]; then
            TARGET[version]="$(target-current-version "$module" "$target")"
            INFO "reinstalling $module:$target..."
            -target-do-remove
        else
            TARGET[version]="${TARGET[version]:-"$( (( $+functions[target-latest-version] )) && target-latest-version )"}"
            INFO "installing $module:$target (version: ${TARGET[version]})."
            -target-install-deps
        fi

        [[ -z "${TARGET[version]}" ]] && ERROR "unable to determine target version."
        TRACE "${reinstall:+re}installing target $module:$target.\n\tVERSION: ${TARGET[version]}\n\tVERBOSE: ${PMM_OPTS[verbose]}"
        -target-do-install && INFO "target installed successfully."
    )
}

# -target-do-install: Does the actual target installation, target
#   environment must be already exported and working directory set.
function -target-do-install() {
    if (( ${PMM_OPTS[verbose]} )); then
        $install_func 2>&1 | tee -a $PMMLOGF || ERROR "error installing target."
    else
        $install_func &>>! $PMMLOGF || ERROR "error installing target (check log file)."
    fi

    # link target binaries.
    for bin ( bin/*(N) ); do util-link "${bin:A}" "$PMMBIND/${bin:t}" || continue; done
    echo "$module | $target | ${TARGET[version]}" >>! "$PMMHOME/pmm.db"
}

# -target-install-deps: Installs the system dependencies.
function -target-install-deps() {
    local command

    (( ${PMM_OPTS[nodeps]} )) || [[ -z "${TARGET[dependencies]}" ]] && return 0

    case "$PMMDIST" in
        arch)
            command=( pacman -Syu --noconfirm ${(s/ /)TARGET[dependencies]} ) ;;
        debian | ubuntu | parrot | kali)
            command=( DEBIAN_FRONTEND=noninteractive apt-get -q -y install ${(s/ /)TARGET[dependencies]} ) ;;
        *)
            ERROR "error handling dependencies on this system, install them manually." ;;
    esac

    if (( ${PMM_OPTS[verbose]} )); then
        sudo -k $command 2>&1 | tee -a $PMMLOGF || ERROR "error installing dependencies."
    else
        sudo -k $command &>>! $PMMLOGF || ERROR "error installing dependencies (check log file)."
    fi
}

# target-do-remove: Does the actual target removing, target
#   environment must be already exported and working directory set.
function -target-do-remove() {
    local uninstall_func; uninstall_func="$(target-get-func uninstall $PMMDIST)"
    
    # run the uninstall function if present.
    if [[ -n "$uninstall_func" ]]; then
        if (( ${PMM_OPTS[verbose]} )); then
            $uninstall_func 2>&1 | tee -a $PMMLOGF || ERROR "error uninstalling target."
        else
            $uninstall_func &>>! $PMMLOGF || ERROR "error uninstalling target (check log file)."
        fi
    fi

    # remove binary links.
    for bin ( bin/*(N) ); do util-unlink "${bin:A}" "$PMMBIND/${bin:t}" || continue; done

    # remove the line in the database file.
    sed -i "\:^${module} \| $target \| ${TARGET[version]}$:d" "$PMMHOME/pmm.db"

    # clean the directory.
    target-clean "$module" "$target"
}

# target-get-func: Prints the name of the requested function, using
#   the supplied variant as preference if available.
function target-get-func() {
    local func_name="$1" variant="$2"

    if [[ -n "$variant" ]] && (( $+functions[target-${func_name}-${variant}] )); then
        echo "target-${func_name}-${variant}"
    else
        (( $+functions[target-$func_name] )) && echo "target-$func_name"
    fi

    return 0
}

# target-current-version: Prints the current installed version of the
#   supplied target.
function target-current-version() {
    local module="$1" target="$2"
    local match mbegin mend MATCH MBEGIN MEND

    for line ( "${(@f)"$(<$PMMHOME/pmm.db)"}" ); do
        if [[ "$line" =~ "^$module \| $target \| (.*)\$" ]]; then
            echo "${match[1]}"
            break
        fi
    done
}

# target-clean: Cleans the target's directory.
function target-clean() {
    local module="$1" target="$2"
    ( cd $PMMREPD/$module/$target && git clean -dffx . 2>&1 >/dev/null )
}

# ]]]
