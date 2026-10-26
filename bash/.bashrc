# Minimal Bash setup with a compact Git-aware prompt.

# Do not run interactive setup for non-interactive shells.
case $- in
    *i*) ;;
    *) return ;;
esac

# Add common user-local command locations without duplicating PATH entries.
for user_bin in "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/bin"; do
    case ":$PATH:" in
        *":$user_bin:"*) ;;
        *) PATH="$user_bin:$PATH" ;;
    esac
done
export PATH

# Build the prompt before each command and show the current Git branch.
__dotfiles_bash_prompt() {
    local previous_status=$?
    local branch git_segment

    branch=$(git branch --show-current 2>/dev/null) || branch=""
    git_segment=""
    if [[ -z "$branch" ]] && git rev-parse --verify HEAD >/dev/null 2>&1; then
        branch="detached"
    fi

    if [[ -n "$branch" ]]; then
        git_segment=" (${branch})"
    fi

    if [[ -n ${TERM:-} && $TERM != dumb ]]; then
        PS1='\[\e[2m\]\w\[\e[0m\]'"${git_segment}"'\$ '
    else
        PS1='\w'"${git_segment}"'\$ '
    fi
    return "$previous_status"
}

# Preserve any prompt hook configured by the environment or another tool.
case ";${PROMPT_COMMAND:-};" in
    *";__dotfiles_bash_prompt;"*) ;;
    *) PROMPT_COMMAND="__dotfiles_bash_prompt${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
esac
