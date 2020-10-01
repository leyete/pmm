# [[[ MODULE

# module-export: Exports the module environment to the following
#   variables:
#   - MODULE: associative array with module details.
#   - MODULE_SYM: symlink specifications.
function module-export() {
    declare -g -A MODULE
    declare -g MODULE_SYM
    local module="$1"

    [[ ! -f "$PMMREPD/$module/module.zsh" ]] && ERROR "missing 'module.zsh' file."
    [[ ! -r "$PMMREPD/$module/module.zsh" ]] && ERROR "cannot read 'module.zsh' file: permission denied."

    MODULE[name]="${module:t}"
    MODULE[path]="$PMMREPD/$module"
    MODULE[repo]="${module:h}"
    MODULE[uri]="${MODULE[repo]}/${MODULE[name]}"

    source $PMMREPD/$module/module.zsh
}

# ]]]
