#!/usr/bin/env bash

CACHE="$HOME/.cache/tarpoon_cache"

touch "$CACHE"

value="$1"

Def_tarpoon() {
    grep -vxF "edit" "$CACHE" >"${CACHE}.tmp"
    mv "${CACHE}.tmp" "$CACHE"
    echo "edit" >>"$CACHE"
}

List_tarpoon() {
    cat "$CACHE"
}

Index_tarpoon() {
    cat -n "$CACHE"
}

Add_tarpoon() {
    dir="$PWD"
    ses_name=$(tmux display-message -p '#S ')

    # echo "$ses_name"

    if ! grep -qxF "$ses_name $dir" "$CACHE"; then
        echo "$ses_name" "$dir" >>"$CACHE"
        notify-send "Added to tarpoon" "$ses_name"
    else
        notify-send "Already exists" "$ses_name"
    fi
}

Already_harpoon() {
    already_session="$1"
    current_session=$(tmux display-message -p '#S')
    # echo "$current_session $already_session"
    if [[ "$already_session" == "$current_session" ]]; then
        notify-send "Already inside the session" "$current_session"
    fi
}

Make_tarpoon() {
    # echo "$path"
    session_name="$1"
    local path="$2"

    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        tmux new-session -ds "$session_name" -c "$path"
    fi
    tmux switch-client -t "$session_name"
}

# List_tarpoon | awk '{ print $1 }'

Check_tarpoon() {
    local session="$1"
    local path="$2"

    if [[ "$session" = "edit" ]]; then
        # exec tmux popup -E "nvim $CACHE"
        tmux new-window -n "edit" nvim "$CACHE"
    else
        Make_tarpoon "$session" "$path"
    fi
}

Jump_tarpoon() {

    local path=$(
        List_tarpoon | fzf \
            --bind "q:abort" \
            --reverse \
            --inline-info \
            --tmux center
    )

    tsession=$(echo "$path" | awk '{print $1}')
    tpath=$(echo "$path" | awk '{print $2}')

    # echo "$tsession"
    # echo "$tpath"

    Already_harpoon "$tsession"

    if [ -n "$path" ]; then
        if [ -n "$TMUX" ]; then
            Check_tarpoon "$tsession" "$tpath"
        fi
    fi
}

Switch_tarpoon() {

    index="$1"
    len_index=$(Index_tarpoon | awk '{print $1}' | tail -n 1)
    len=$((len_index - 1))
    # echo "$len_index" && echo "$index" && echo "$len"
    if [[ "$index" -le 0 || "$index" -gt "$len" ]]; then
        notify-send "Invalid Index" "$index"
    fi

    session_name=$(Index_tarpoon | awk -v i="$index" 'NR==i {print $2}')
    path=$(Index_tarpoon | awk -v i="$index" 'NR==i {print $3}')

    echo "$session_name"
    echo "$path"

    Already_harpoon

    Check_tarpoon "$session_name" "$path"
}

Combine_tarpoon() {
    if [[ -n "$1" ]]; then
        Switch_tarpoon "$1"
    else
        Jump_tarpoon
    fi

}

Readme_tarpoon() {
    xdg-open "https://github.com/hellopradeep69/tarpoon.git"
}

Help_tarpoon() {
    echo
    echo "Usage:"
    echo "    ${0##*/} [options] [args]"
    echo "Options:"
    echo "    -H                       Track current tmux session"
    echo "    -h                       List tracked sessions and choose one interactively"
    echo "    -h <index>               Switch to the tarpoon session at the given index"
    echo "    -hn                      Jump to the next tracked session"
    echo "    -hp                      Jump to the previous tracked session"
    echo "    -readme                  For more info"
    echo "    -help                    Display this help message"
    echo "Examples: "
    echo "    ${0##*/} -H"
    echo "    ${0##*/} -h"
    echo "    ${0##*/} -h 2"
    echo "    ${0##*/} -hn"
    echo "    ${0##*/} -hp"
}

Next_tarpoon() {
    current_session="$(tmux display-message -p '#S')"
    total="$(Index_tarpoon | awk '{print $1}' | tail -n 1)"

    current_index=$(Index_tarpoon | awk -v s="$current_session" '$2 == s {print NR}')
    next_index=$((current_index + 1))

    if [[ "$next_index" = "$total" ]]; then
        next_index=1
    fi

    session_name=$(Index_tarpoon | awk -v i="$next_index" 'NR==i {print $2}')
    path=$(Index_tarpoon | awk -v i="$next_index" 'NR==i {print $3}')

    notify-send "Next_tarpoon" "$session_name"
    Check_tarpoon "$session_name" "$path"
}

Previous_tarpoon() {

    current_session="$(tmux display-message -p '#S')"
    total="$(Index_tarpoon | awk '{print $1}' | tail -n 1)"
    total=$((total - 1))
    echo "$total"

    current_index=$(Index_tarpoon | awk -v s="$current_session" '$2 == s {print NR}')
    prev_index=$((current_index - 1))

    if [[ "$prev_index" -lt 1 ]]; then
        prev_index="$total"

    fi

    session_name=$(Index_tarpoon | awk -v i="$prev_index" 'NR==i {print $2}')
    path=$(Index_tarpoon | awk -v i="$prev_index" 'NR==i {print $3}')

    notify-send "Previous tarpoon" "$session_name"
    Check_tarpoon "$session_name" "$path"
}

Def_tarpoon

case "$value" in
-H)
    Add_tarpoon
    ;;
-h)
    Combine_tarpoon "$2"
    ;;
-hn)
    Next_tarpoon
    ;;
-hp)
    Previous_tarpoon
    ;;
-readme)
    Readme_tarpoon
    ;;
*)
    Help_tarpoon
    ;;
esac

# Add_tarpoon
# Jump_tarpoon "$(List_tarpoon | fzf)"
