# [[[ REPO

# repo-update: Updates the supplied local repository.
function repo-update() {
    local repo="$1"

    # make sure this is a git repository.
    [[ -d "$repo/.git" ]] || ERROR "repository '$repo' is not a git repository (missing .git subdirectory)."

    INFO "updating '$repo' repository..."
    if (( ${PMM_OPTS[verbose]} )); then
        git --git-dir="$repo/.git" --work-tree="$repo" --no-pager pull origin | tee -a $PMMLOGF
    else    
        git --git-dir="$repo/.git" --work-tree="$repo" --no-pager pull origin &>>! $PMMLOGF \
            || ERROR "error updating repository (check log file)."
    fi
}

# repo-ensure: Ensures there is a local clone of the supplied repo.
function repo-ensure() {
    local repo="$1" branch url clone_dir

    url="$(repo-expand-url $repo)"
    branch="$(repo-parse-branch $repo $url)"
    clone_dir="$(repo-clone-dir $repo $branch)"

    TRACE "repo-ensure - $repo\n\turl: $url\n\tclone dir: $clone_dir\n\tbranch: ${branch:-master}"

    if [[ -d "$PMMREPD/$clone_dir" || ${PMM_OPTS[noclone]} -eq 1 ]]; then
        TRACE "repository already available locally."
        return 0
    fi

    INFO "cloning '$url' repository..."
    if (( ${PMM_OPTS[verbose]} )); then
        git clone --branch "${branch:-master}" -- "$url" "$PMMREPD/$clone_dir" 2>&1 | tee -a $PMMLOGF
    else
        git clone --branch "${branch:-master}" -- "$url" "$PMMREPD/$clone_dir" &>>! $PMMLOGF \
            || ERROR "error cloning repository (check log file)."
    fi
}

# repo-expand-url: Expands a repo string to a URL.
function repo-expand-url() {
    local match mbegin mend MATCH MBEGIN MEND

    if [[ "$1" =~ '^([A-Za-z\-\d]+)/([A-Za-z\-\d]+)(@(.*))?$' ]]; then
        echo "https://github.com/${match[1]}/${match[2]}.git"
    else
        ERROR "'$1' is not a valid repo string." 
    fi
}

# repo-parse-branch: Parses the branch for the supplied repo string.
function repo-parse-branch() {
    local repo="$1" url="$2" branch branches
    local match mbegin mend MATCH MBEGIN MEND

    [[ "$repo" =~ '^([A-Za-z\-\d]+)/([A-Za-z\-\d]+)(@(.*))?$' ]] && branch="${match[4]}"

    if [[ "$branch" =~ '\*' ]]; then
        branches=$(git ls-remote --tags -q "$url" "$branch"|cut -d'/' -f3|sort -n|tail -1)
        branch=${${${branches#*/*/}%^*}}  # remove references
    fi

    echo "$branch"
}

# repo-clone-dir: Prints the directory path from $PMMREPD where the
#   target's repository should be cloned.
function repo-clone-dir() {
    local repo="$1" branch="$2"
    echo "${repo%@*}${branch:+"@${${branch//\*/x}//\//-}"}"
}

# ]]]
