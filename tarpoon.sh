#!/usr/bin/env bash

CACHE="$HOME/.cache/tarpoon_cache"

touch "$CACHE"

value="$1"

List_harpoon() {
    cat "$CACHE"
}

Add_harpoon() {
    dir="$PWD"
    grep -qxF "$dir" "$CACHE" || echo "$dir" >>"$CACHE"
}

Home_harpoon() {
    local session_name="home"

    if tmux has-session -t "$session_name" 2>/dev/null; then
        [ -n "$TMUX" ] && tmux switch-client -t "$session_name" || tmux attach -t "$session_name"
    else
        tmux new-session -d -s "$session_name" -c "$HOME" -n "main"
        [ -n "$TMUX" ] && tmux switch-client -t "$session_name" || tmux attach -t "$session_name"
    fi
    exit 0

}

Make_harpoon() {
    session_name=$(basename "$path" | tr . _)

    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        tmux new-session -ds "$session_name" -c "$path"
    fi
    tmux switch-client -t "$session_name"
}

Check_harpoon() {
    local path="$1"

    if [[ "$HOME" = "$path" ]]; then
        Home_harpoon
    else
        Make_harpoon
    fi
}

Jump_harpoon() {

    local path=$(
        List_harpoon | fzf \
            --bind "q:abort" \
            --inline-info \
            --tmux center
    )

    if [ -d "$path" ]; then
        if [ -n "$TMUX" ]; then
            Check_harpoon "$path"
        fi
    fi
}

case "$value" in
-H)
    Add_harpoon
    ;;
-h)
    Jump_harpoon
    ;;
*)
    echo "huf"
    ;;
esac

# Add_harpoon
# Jump_harpoon "$(List_harpoon | fzf)"
