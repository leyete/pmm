# [[[ UTILITY

# util-print-list: Prints the supplied list of arguments in a
#   visually pleasant format.
function util-print-list() {
    declare -i index=1 cols=$(echoti cols)
    declare -i remaining=$cols padding=$(( cols / 4 ))

    printf "\n"

    for word ( $@ ); do
        if (( ${#word} + 5 > $remaining )); then
            printf "\n"
            remaining=$cols
        fi

        if (( $padding + 5 > $remaining )); then
            printf "%2d) %s " $index $word
        else
            printf "%2d) %-${padding}s " $index $word
        fi

        (( remaining -= 5 + $(( ${#word} > $padding ? ${#word} : $padding )) ))
        (( index++ ))
    done

    printf "\n" 
}

# util-select-from: Asks the user to choose an item from a
#   list of supplied options.
function util-select-from() {
    local message="$1" user_selection; shift
    local match mbegin mend MATCH MBEGIN MEND

    # mantain default selection, if none default to 1.
    selection=${selection:-1}

    # do not prompt if --noconfirm is supplied.
    (( ${PMM_OPTS[noconfirm]} )) && return

    INFO "$message"
    util-print-list $@
    print -n "\n:: Select an option [default=$selection]: " && read -r user_selection

    # check the selection.
    [[ -z "$user_selection" ]] && return
    [[ "$user_selection" =~ '^\d+$' ]] && (( $user_selection > 0 && $user_selection < ( ${#@} + 1 ) )) \
        && selection="$user_selection"
}

# util-ask-boolean: Asks the user a yes/no question.
function util-ask-boolean() {
    local message="$1" answer
    local match mbegin mend MATCH MBEGIN MEND

    # do not prompt if --noconfirm is supplied.
    (( ${PMM_OPTS[noconfirm]} )) && return

    while true; do
        INFO "$message"
        printf ":: Select an option [Y/n]: " && read -r answer
        
        [[ -z "$answer" || "${(L)answer}" =~ "^y(es)?$" ]] && return 0
        [[ "${(L)answer}" =~ "^n(o)?$" ]] && return 1

        # invalid answer.
        printf ":: Invalid answer, please type y (yes) or n (no).\n"
    done
}

# util-link: Links the supplied file to the specified location.
function util-link() {
    local file="$1" dest="$2"

    if [[ -f "$dest" || -d "$dest" || -L "$dest" ]]; then
        # destination file exists, check if it's a link to $file
        [[ "${dest:A}" == "$file" ]] && return
        
        # if the destination file exists but it isn't a link to $file, back it
        # up before linking
        if [[ ! -w "${dest:h}" ]]; then
            util-ask-boolean "you don't have write permission on the destination, would you like to use sudo?" \
                && sudo -k mv "$dest" "${dest}.old" 2>&1 >> $PMMLOGF || ERROR "$dest: permission denied."
        else
            mv "$dest" "${dest}.old" 2>&1 >> $PMMLOGF
        fi
        
        WARN "$dest already exists, moved to ${dest}.old"
    fi
    
    # link the file to the destination
    if [[ ! -w "${dest:h}" ]]; then
        if util-ask-boolean "you don't have write permission on the destination, would you like to use sudo?"; then
            sudo -k ln -sf "$file" "$dest" 2>&1 >> $PMMLOGF
        fi
    else
        ln -sf "$file" "$dest" 2>&1 >> $PMMLOGF
    fi
}

# util-unlink: Unlinks the supplied file only if the symlink ($2)
#   points to the source ($1).
function util-unlink() {
    local src="$1" sym="$2"
    [[ "${sym:A}" != "$src" ]] && return 0

    if [[ ! -w "${sym:h}" ]]; then
        if util-ask-boolean "you don't have write permission on the destination, would you like to use sudo?"; then
            sudo -k unlink $sym 2>&1 >> $PMMLOGF
        fi
    else
        unlink "$sym" 2>&1 >> $PMMLOGF
    fi
}

# ]]]
