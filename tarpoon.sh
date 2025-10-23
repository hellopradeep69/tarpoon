#!/usr/bin/env bash

CACHE="$HOME/.cache/tarpoon_cache"

touch "$CACHE"

value="$1"

Def_harpoon() {
    grep -vxF "edit" "$CACHE" >"${CACHE}.tmp"
    mv "${CACHE}.tmp" "$CACHE"
    echo "edit" >>"$CACHE"
}

List_harpoon() {
    # cat "$CACHE" | nl
    cat -n "$CACHE"
}

Add_harpoon() {
    dir="$PWD"
    basedir="$(basename "$dir")"

    if ! grep -qxF "$dir" "$CACHE"; then
        echo "$dir" >>"$CACHE"
        notify-send "Added to Harpoon" "$basedir"
    else
        notify-send "Already exists" "$basedir"
    fi

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
    local path="$1"
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
        Make_harpoon "$path"
    fi
}

Jump_harpoon() {

    local path=$(
        List_harpoon | fzf \
            --bind "q:abort" \
            --reverse \
            --inline-info \
            --tmux center | awk '{print $2}'
    )

    # echo "$path"

    if [ -d "$path" ]; then
        if [ -n "$TMUX" ]; then
            Check_harpoon "$path"
        fi
    elif [[ "$path" = "edit" ]]; then
        tmux new-window -n "edit" nvim "$CACHE"
    fi
}

Switch_harpoon() {

    index="$1"
    len_index=$(List_harpoon | awk '{print $1}' | tail -n 1)
    len=$((len_index - 1))
    # echo "$len_index" && echo "$index" && echo "$len"
    if [[ "$index" -le 0 || "$index" -gt "$len" ]]; then
        notify-send "Invalid Index" "$index"
    fi

    path=$(List_harpoon | awk -v i="$index" 'NR==i {print $2}')
    # echo "$path"

    Check_harpoon "$path"
}

Combine_harpoon() {
    if [[ -n "$1" ]]; then
        Switch_harpoon "$1"
    else
        Jump_harpoon
    fi

}

Readme_harpoon() {
    xdg-open "https://github.com/hellopradeep69/tarpoon.git"
}

Help_harpoon() {
    echo
    echo "Usage:"
    echo "    ${0##*/} [options] [args]"
    echo "Options:"
    echo "    -H                       Track current tmux session"
    echo "    -h                       List tracked sessions and choose one interactively"
    echo "    -h <index>               Switch to the harpoon session at the given index"
    echo "    -readme                  For more info"
    echo "    -help                    Display this help message"
    echo "Examples: "
    echo "    ${0##*/} -H"
    echo "    ${0##*/} -h"
    echo "    ${0##*/} -h 2"
}

Def_harpoon

case "$value" in
-H)
    Add_harpoon
    ;;
-h)
    Combine_harpoon "$2"
    ;;
-readme)
    Readme_harpoon
    ;;
*)
    Help_harpoon
    ;;
esac

# Add_harpoon
# Jump_harpoon "$(List_harpoon | fzf)"
