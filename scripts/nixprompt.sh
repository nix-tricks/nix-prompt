#!/bin/bash
# Copyright (c) 2026 NIX tricks
# Released under the MIT License
# SPDX-License-Identifier: MIT


### Setup

config() {
    # Define prompt segments
    declare -ag segments=(identity timestamp path git prompt)
    declare -ag dynamics=(identity git)

    # Define active features
    declare -g use_colors=true
    declare -g use_glyphs=true
    declare -g use_badges=true

    # Define custom colors
    declare -g color_primary="#f5992e"
    declare -g color_secondary="#785cea"
    declare -g color_neutral="#5f5f87"
    declare -g color_global

    declare -g glyph_badge_left=""
    declare -g glyph_badge_right=""

    # Define main color
    if is_root; then
        color_global=$color_secondary
    else
        color_global=$color_primary
    fi

    # Define prompt variables
    PS1=""
    PS2="→ "
    PROMPT_DIRTRIM=2
    export GIT_PS1_SHOWUNTRACKEDFILES=1
    export GIT_PS1_SHOWDIRTYSTATE=1

    # Preserve prompt command (i.e. not to break VTE)
    if [[ $PROMPT_COMMAND != *__print_blank* ]]; then
        PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }__print_blank"
    fi
}

init() {
    for segment in "${segments[@]}"; do
        # Compute function name
        renderer="render_$segment"

        # Skip segments without renderers
        if ! declare -F "$renderer" > /dev/null; then continue; fi

        if [[ "${dynamics[*]}" =~ $segment ]]; then
            # Evaluate every time
            PS1+="\$($renderer) "
        else
            # Evaluate only once
            PS1+="$($renderer) "
        fi
    done
}


### Renderers

render_identity() {
    local status=$?
    local glyph
    local label

    # Define glyph
    if is_error "$status"; then
        if $use_glyphs; then glyph=""; else glyph="!"; fi
    elif is_ssh; then
        if $use_glyphs; then glyph="󰌘"; else glyph="*"; fi
    elif is_root; then
        if $use_glyphs; then glyph=""; else glyph="#"; fi
    else
        if $use_glyphs; then glyph=""; else glyph="$"; fi
    fi

    # Define label
    if is_ssh || is_su; then
        label="$USER@$HOSTNAME"
    elif is_git; then
        label=$(get_git_project)
    else
        label="$HOSTNAME"
        # or "$(date +%I:%M:%S)"
    fi

    # Rendering logic
    if $use_badges; then
        make_badge "$glyph $label"
    else
        make_label "$glyph $label"
    fi
}

render_timestamp() {
    local label="\T"

    # Rendering logic
    if $use_badges; then
        make_label "$label"
    else
        make_label "[$label]" "$color_neutral"
    fi
}

render_path() {
    local glyph=" "
    local label="\w"

    # Rendering logic
    if $use_glyphs; then
        printf "%s %s" "$(make_label "$glyph")" "$label"
    else
        printf "%s" "$label"
    fi
}

render_git() {
    local glyph=""
    local label="%s"

    # Prevent if not a repository
    if ! is_git; then return 1; fi

    # Use brackets instead of badges
    if ! $use_badges; then
        label="($label)"
    fi

    # Prepend glyph to label
    if $use_glyphs; then
        label="$glyph $label"
    fi

    # Rendering logic
    if $use_badges; then
        format="$(make_badge "$label" "$color_neutral")"
    elif $use_colors; then
        format="$(make_label "$label" "$color_secondary")"
    else
        format="$label"
    fi

    # Safe git prompt
    if command -v __git_ps1 >/dev/null 2>&1; then
        __git_ps1 "$format"
    fi
}

render_prompt() {
    local glyph

    # Define glyph
    if $use_glyphs && $use_badges; then glyph="󱞩"; else glyph="↳"; fi

    # Prepend space character to match badge
    if $use_badges; then glyph=" $glyph"; fi

    # Use bold glyph
    if $use_glyphs && $use_badges; then
        glyph="\001\033[1m\002$glyph\001\033[0m\002"
    fi

    # Prepend newline character
    printf "\n%s" "$(make_label "$glyph")"
}


### Helpers

hex_to_ansi() {
    local hex=${1#\#}
    local include_bg=${2:-false}

    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))

    # Set truecolor bg while keeping default fg
    if $include_bg; then printf "30;48;"; fi

    printf "2;%s;%s;%s" "$r" "$g" "$b"
}

make_label() {
    local content=$1
    local color=${2:-$color_global}

    # Prevent null content
    if [[ -z $content ]]; then return 1; fi

    if $use_colors; then
        printf "\001\033[38;%sm\002" "$(hex_to_ansi "$color")"
    fi

    # Print text content
    printf "%s" "$content"

    if $use_colors; then
        # Reset foreground color
        printf "\001\033[0m\002"
    fi
}

make_badge() {
    local content=$1
    local color=${2:-$color_global}
    local glyph_left
    local glyph_right
    local ansi_sequence

    # Prevent null content
    if [[ -z $content ]]; then return 1; fi

    if $use_glyphs; then
        # Use rounded corners
        glyph_left=$glyph_badge_left
        glyph_right=$glyph_badge_right
    else
        # Use basic padding
        content=" $content "
    fi

    if $use_colors; then
        # Set background and foreground sequence
        ansi_sequence=$(hex_to_ansi "$color" true)
    else
        # Reverse video
        ansi_sequence=7
    fi

    # Rendering logic
    printf "%s" "$(make_label "$glyph_left" "$color")"
    printf "\001\033[%sm\002" "$ansi_sequence"
    printf "%s" "$content"
    printf "\001\033[0m\002"
    printf "%s" "$(make_label "$glyph_right" "$color")"
}

is_root() { [[ $EUID -eq 0 ]]; }

is_su() { [[ -n $LOGNAME && $USER != "$LOGNAME" ]]; }

is_ssh() { [[ -n "$SSH_CLIENT" ]]; }

is_error() { [[ $1 -ne 0 && $1 -ne 130 ]]; }

is_git() { [[ -n $(get_git_project) ]]; }

# Get top-level repository name
get_git_project() {
    # Skip execution if `git` is not available
    if ! command -v git > /dev/null 2>&1; then return 1; fi

    if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
        # Return the directory basename
        printf "%s" "${git_root##*/}"
    fi
}

# Prepend blank line except after startup or clear
__print_blank() { [[ -n $__was_printed ]] && echo; __was_printed=1; }

# The clear command should also reset the flag
alias clear="command clear; unset __was_printed"


### Initialize

config && init
