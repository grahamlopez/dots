#!/usr/bin/env bash
# Scan home directory for git repos and print a pretty status summary

# ── Bare repos ────────────────────────────────────────────────────────────────
# Bare git repos that use a separate work tree (e.g. dotfiles).
# Format: "git-dir:work-tree"  — both support ~ expansion.
BARE_REPOS=(
    ~/.dots-git:~
)
# ─────────────────────────────────────────────────────────────────────────────

# ── Ignore list ───────────────────────────────────────────────────────────────
# Paths to skip during the scan. Supports:
#   - Exact paths (absolute or ~-prefixed):  ~/some/path
#   - Glob patterns matched against repo path: **/vendor/**
# Repos whose path starts with or matches any entry will be skipped.
IGNORE_PATHS=(
    ~/.claude/plugins          # plugin marketplace repos — noisy
    ~/Synct                    # syncthing-managed, not real dev repos
    ~/.nvm
)
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# Colors
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
RESET='\033[0m'

# Icons
ICON_REPO="󰊢"
ICON_AHEAD="↑"
ICON_BEHIND="↓"
ICON_DIVERGED="↕"
ICON_CLEAN="✓"
ICON_DIRTY="✗"
ICON_STAGED="●"
ICON_MODIFIED="±"
ICON_UNTRACKED="?"
ICON_DETACHED="⚠"

DO_FETCH=false
if [[ "${1:-}" == "--fetch" ]]; then
    DO_FETCH=true
    shift
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    cat <<EOF

USAGE
    $(basename "$0") [PATH]
    $(basename "$0") -h | --help

DESCRIPTION
    Scans a directory recursively for git repositories and prints a summary
    of each one's status relative to its upstream.

ARGUMENTS
    --fetch  Fetch from upstream before checking status. Gives accurate
             behind/ahead counts at the cost of speed and network access.
    PATH     Directory to scan. Defaults to \$HOME if omitted.

OUTPUT
    Each repository shows:
      branch   Current branch name and its upstream tracking ref.
      sync     Relationship to upstream: up to date, ahead (unpushed
               commits), behind (incoming commits), or diverged (both).
      state    Working tree cleanliness. Dirty repos list counts of
               staged, modified, untracked, and unmerged files.
      last     Subject of the most recent commit, its author, and how
               long ago it was made.

BARE REPOS
    Bare repos (e.g. a dotfiles repo with \$HOME as the work tree) are not
    found by the directory scan. List them explicitly in the BARE_REPOS
    array at the top of the script:

        BARE_REPOS=(
            "~/.dots-git:~"
        )

    Format is "git-dir:work-tree". Both sides support ~ expansion.

    A bare repo is included in the output when its git-dir or work-tree
    falls within the PATH being scanned (or always when using the default
    \$HOME scan).

IGNORE LIST
    Add paths to IGNORE_PATHS at the top of the script to skip repos under
    those directories. Prefix matching is used, so ignoring ~/foo will also
    skip ~/foo/bar. Both absolute paths and ~-prefixed paths are supported.

    The summary line at the bottom reports how many repos were skipped and
    which configured ignore prefixes actually matched something.

EXAMPLES
    $(basename "$0")                  Scan entire home directory
    $(basename "$0") ~/work           Scan only ~/work
    $(basename "$0") --fetch ~/work   Fetch remotes first, then scan ~/work
    $(basename "$0") ~/work/myrepo    Scan a single repo directory

EOF
    exit 0
fi

HOME_DIR="${1:-$HOME}"

print_separator() {
    printf "${DIM}%s${RESET}\n" "$(printf '─%.0s' {1..70})"
}

summarize_repo() {
    local git_dir="$1"   # path to .git dir or bare repo dir
    local work_tree="$2" # path to working tree

    local display_name
    display_name=$(basename "$work_tree")
    [[ "$display_name" == "$(basename "$HOME")" ]] && display_name=$(basename "$git_dir")

    local display_path
    [[ "$work_tree" == "$HOME"* ]] \
        && display_path="~${work_tree#$HOME}" \
        || display_path="$work_tree"

    # Wrapper: all git commands use explicit git-dir + work-tree
    local g=(git --git-dir="$git_dir" --work-tree="$work_tree")

    # Get branch
    local branch
    local detached=false
    branch=$("${g[@]}" symbolic-ref --short HEAD 2>/dev/null) || {
        branch=$("${g[@]}" rev-parse --short HEAD 2>/dev/null || echo "unknown")
        detached=true
    }

    # Fetch upstream if requested
    if $DO_FETCH; then
        "${g[@]}" fetch --quiet 2>/dev/null || true
    fi

    # Get upstream tracking info
    local upstream ahead behind
    upstream=$("${g[@]}" rev-parse --abbrev-ref "@{upstream}" 2>/dev/null || echo "")

    if [[ -n "$upstream" ]]; then
        ahead=$("${g[@]}" rev-list --count "@{upstream}..HEAD" 2>/dev/null || echo 0)
        behind=$("${g[@]}" rev-list --count "HEAD..@{upstream}" 2>/dev/null || echo 0)
    else
        ahead=0
        behind=0
    fi

    # Get working tree status
    local staged=0 modified=0 untracked=0 unmerged=0
    while IFS= read -r line; do
        local xy="${line:0:2}"
        case "$xy" in
            "??") (( ++untracked )) ;;
            "UU"|"AA"|"DD"|"AU"|"UA"|"DU"|"UD") (( ++unmerged )) ;;
            *)
                [[ "${xy:0:1}" != " " && "${xy:0:1}" != "?" ]] && (( ++staged ))  || true
                [[ "${xy:1:1}" != " " && "${xy:1:1}" != "?" ]] && (( ++modified )) || true
                ;;
        esac
    done < <("${g[@]}" status --porcelain 2>/dev/null)

    # Last commit info
    local last_commit last_author last_date
    last_commit=$("${g[@]}" log -1 --pretty=format:"%s" 2>/dev/null | cut -c1-50 || echo "")
    last_author=$("${g[@]}" log -1 --pretty=format:"%an" 2>/dev/null || echo "")
    last_date=$("${g[@]}" log -1 --pretty=format:"%cr" 2>/dev/null || echo "")

    # --- Print ---
    print_separator
    printf "${BOLD}${BLUE}${ICON_REPO}  %s${RESET}  ${DIM}%s${RESET}\n" \
        "$display_name" "$display_path"

    # Branch line
    if $detached; then
        printf "  ${ICON_DETACHED} ${YELLOW}detached HEAD${RESET} @ ${CYAN}%s${RESET}\n" "$branch"
    else
        printf "  branch  ${CYAN}%s${RESET}" "$branch"
        if [[ -n "$upstream" ]]; then
            printf "  ${DIM}→ %s${RESET}" "$upstream"
        else
            printf "  ${DIM}(no upstream)${RESET}"
        fi
        printf "\n"
    fi

    # Upstream sync status
    if [[ -n "$upstream" ]]; then
        if (( ahead > 0 && behind > 0 )); then
            printf "  sync    ${YELLOW}${ICON_DIVERGED} diverged${RESET}  ${GREEN}${ICON_AHEAD}%d${RESET} ahead  ${RED}${ICON_BEHIND}%d${RESET} behind\n" \
                "$ahead" "$behind"
        elif (( ahead > 0 )); then
            printf "  sync    ${YELLOW}${ICON_AHEAD}%d ahead${RESET} of upstream\n" "$ahead"
        elif (( behind > 0 )); then
            printf "  sync    ${RED}${ICON_BEHIND}%d behind${RESET} upstream\n" "$behind"
        else
            printf "  sync    ${GREEN}${ICON_CLEAN} up to date${RESET}\n"
        fi
    fi

    # Working tree status
    local dirty=false
    (( staged + modified + untracked + unmerged > 0 )) && dirty=true || true

    if $dirty; then
        printf "  state   ${RED}${ICON_DIRTY} dirty${RESET} "
        (( staged    > 0 )) && printf " ${GREEN}${ICON_STAGED}%d staged${RESET}" "$staged"
        (( modified  > 0 )) && printf " ${YELLOW}${ICON_MODIFIED}%d modified${RESET}" "$modified"
        (( untracked > 0 )) && printf " ${DIM}${ICON_UNTRACKED}%d untracked${RESET}" "$untracked"
        (( unmerged  > 0 )) && printf " ${RED}⚡%d unmerged${RESET}" "$unmerged"
        printf "\n"
    else
        printf "  state   ${GREEN}${ICON_CLEAN} clean${RESET}\n"
    fi

    # Last commit
    if [[ -n "$last_commit" ]]; then
        printf "  last    ${DIM}%s${RESET}  ${DIM}by %s, %s${RESET}\n" \
            "$last_commit" "$last_author" "$last_date"
    fi
}

main() {
    printf "\n${BOLD}${MAGENTA}Git Repository Status — %s${RESET}\n" "$(date '+%Y-%m-%d %H:%M')"
    printf "${DIM}Scanning: %s${RESET}\n\n" "${HOME_DIR/#$HOME/~}"

    local count=0
    local repos=()

    # Find all .git directories, skip hidden dirs and common noise
    while IFS= read -r gitdir; do
        repos+=("${gitdir%/.git}")
    done < <(find "$HOME_DIR" \
        -name ".git" -type d \
        -not -path "*/.git/*" \
        -not -path "*/node_modules/*" \
        -not -path "*/.cache/*" \
        -not -path "*/.local/share/Trash/*" \
        2>/dev/null | sort)

    if (( ${#repos[@]} == 0 )); then
        printf "${YELLOW}No git repositories found in %s${RESET}\n" "${HOME_DIR/#$HOME/~}"
        exit 0
    fi

    # Expand ~ in ignore list entries
    local expanded_ignores=()
    for p in "${IGNORE_PATHS[@]}"; do
        expanded_ignores+=("${p/#\~/$HOME}")
    done

    local ignored_count=0
    local ignored_paths=()

    for repo in "${repos[@]}"; do
        local skip=false
        local matched_ignore=""
        for ignore in "${expanded_ignores[@]}"; do
            if [[ "$repo" == "$ignore"* ]]; then
                skip=true
                matched_ignore="$ignore"
                break
            fi
        done
        if $skip; then
            ((ignored_count++)) || true
            # Record unique ignore prefixes that actually matched
            local already_listed=false
            for listed in "${ignored_paths[@]+"${ignored_paths[@]}"}"; do
                [[ "$listed" == "$matched_ignore" ]] && already_listed=true && break
            done
            $already_listed || ignored_paths+=("$matched_ignore")
            continue
        fi

        summarize_repo "$repo/.git" "$repo"
        ((count++)) || true
    done

    # Bare repos — included when git-dir or work-tree falls within HOME_DIR
    for entry in "${BARE_REPOS[@]+"${BARE_REPOS[@]}"}"; do
        local git_dir="${entry%%:*}"
        local work_tree="${entry#*:}"
        git_dir="${git_dir/#\~/$HOME}"
        work_tree="${work_tree/#\~/$HOME}"
        [[ "$git_dir" == "$HOME_DIR"* || "$work_tree" == "$HOME_DIR"* ]] || continue
        [[ -d "$git_dir" ]] || { printf "${YELLOW}bare repo not found: %s${RESET}\n" "$git_dir"; continue; }
        summarize_repo "$git_dir" "$work_tree"
        ((count++)) || true
    done

    print_separator
    printf "\n${BOLD}%d repositor%s found${RESET}\n" \
        "$count" "$([ "$count" -eq 1 ] && echo 'y' || echo 'ies')"
    if (( ignored_count > 0 )); then
        local pretty_paths=()
        for p in "${ignored_paths[@]}"; do
            [[ "$p" == "$HOME"* ]] && pretty_paths+=("~${p#$HOME}") || pretty_paths+=("$p")
        done
        local joined
        joined=$(printf ", %s" "${pretty_paths[@]}"); joined="${joined:2}"
        printf "${DIM}(%d ignored: %s)${RESET}\n" "$ignored_count" "$joined"
    fi
    printf "\n"
}

main
