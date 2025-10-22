#!/usr/bin/env bash
# tmux-harpoon.sh

HARPOON_FILE="${HOME}/.tmux_harpoon"

# Ensure file exists
touch "$HARPOON_FILE"

function list_targets() {
    cat "$HARPOON_FILE"
}

function add_target() {
    local path="$1"
    # Avoid duplicates
    grep -qxF "$path" "$HARPOON_FILE" || echo "$path" >>"$HARPOON_FILE"
}

function jump_to_target() {
    local path="$1"
    if [ -d "$path" ]; then
        # If inside tmux, create a new session in that dir
        if [ -n "$TMUX" ]; then
            local session_name
            session_name=$(basename "$path")
            # Create new session if not exists
            if ! tmux has-session -t "$session_name" 2>/dev/null; then
                tmux new-session -ds "$session_name" -c "$path"
            fi
            tmux switch-client -t "$session_name"
        else
            cd "$path" || exit
            exec $SHELL
        fi
    else
        echo "Directory does not exist: $path"
    fi
}

# If first argument is 'add', add current dir or given path
if [ "$1" = "add" ]; then
    add_target "${2:-$PWD}"
    exit
fi

# Show fzf menu to select target
target=$(list_targets | fzf --prompt="Harpoon > " --height 10 --border)

[ -n "$target" ] && jump_to_target "$target"
