#!/bin/zsh
# Copyright (c) 2026 NIX tricks
# Released under the MIT License
# SPDX-License-Identifier: MIT


### Setup

config() {
    # Define prompt segments
    typeset -ga segments=(identity timestamp path git prompt)
    typeset -ga dynamics=(identity git)

    # Define active features
    typeset -g use_colors=true
    typeset -g use_glyphs=true
    typeset -g use_badges=true

    # Define custom colors
    typeset -g color_primary="#f5992e"
    typeset -g color_secondary="#785cea"
    typeset -g color_neutral="#5f5f87"
    typeset -g color_global

    typeset -g glyph_badge_left=""
    typeset -g glyph_badge_right=""

    # Define main color
    if is_root; then
        color_global=$color_secondary
    else
        color_global=$color_primary
    fi

    # Prevent NF glyphs on console sessions
    if is_console; then use_glyphs=false; fi

    # Define prompt variables
    setopt PROMPT_SUBST
    PS1=""
    PS2="→ "
    export GIT_PS1_SHOWUNTRACKEDFILES=1
    export GIT_PS1_SHOWDIRTYSTATE=1

    # Preserve prompt hook
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd __print_blank
}

init() {
    for segment in "${segments[@]}"; do
        local renderer="render_$segment"

        # Skip segments without renderers
        if ! typeset -f "$renderer" > /dev/null; then continue; fi

        if (( ${dynamics[(I)$segment]:-0} )); then
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
    local cmd_status=$?
    local glyph
    local label

    # Define glyph
    if is_error "$cmd_status"; then
        if $use_glyphs; then glyph=""; else glyph="!"; fi
        # Add blinking effect to error state glyph
        glyph="%{\033[5m%}$glyph%{\033[25m%}"
    elif is_ssh; then
        if $use_glyphs; then glyph="󰌘"; else glyph="*"; fi
    elif is_root; then
        if $use_glyphs; then glyph=""; else glyph="#"; fi
    else
        if $use_glyphs; then glyph=""; else glyph="$"; fi
    fi

    # Define label
    if is_ssh || is_su; then
        label="%n@%m"
    elif is_git; then
        label=$(get_git_project)
    else
        label="%m"
    fi

    # Rendering logic
    if $use_badges; then
        make_badge "$glyph $label"
    else
        make_label "$glyph $label"
    fi
}

render_timestamp() {
    local label="%D{%I:%M:%S}"

    # Rendering logic
    if $use_badges; then
        make_label "$label"
    else
        make_label "[$label]" "$color_neutral"
    fi
}

render_path() {
    local glyph=""
    local label="%(3~|.../%2~|%~)"

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
    local format

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

    # Build format string
    if $use_badges; then
        format="$(make_badge "$label" "$color_neutral")"
    elif $use_colors; then
        format="$(make_label "$label" "$color_secondary")"
    else
        format="$label"
    fi

    # Safe git prompt
    if command -v __git_ps1 > /dev/null 2>&1; then
        __git_ps1 "$format"
        return
    fi

    # Native git fallback for Zsh
    local git_branch git_status=""
    git_branch=$(
        git branch --show-current 2>/dev/null ||
        git rev-parse --short HEAD 2>/dev/null
    )

    [[ -z "$git_branch" ]] && return

    if [[ "$GIT_PS1_SHOWDIRTYSTATE" == "1" ]]; then
        git diff --quiet 2>/dev/null || git_status+="*"
        git diff --cached --quiet 2>/dev/null || git_status+="+"
    fi

    if [[ "$GIT_PS1_SHOWUNTRACKEDFILES" == "1" ]]; then
        local untracked
        untracked=$(git ls-files --others --exclude-standard 2>/dev/null)
        [[ -n "$untracked" ]] && git_status+="%"
    fi

    [[ -n "$git_status" ]] && git_branch+=" $git_status"

    # Escape % so Zsh prompt prints them literally
    git_branch="${git_branch//\%/%%}"

    # Substitute %s with the git branch string
    printf "%s" "${format//\%s/$git_branch}"
}

render_prompt() {
    local glyph

    # Define glyph
    if $use_glyphs && $use_badges; then glyph="󱞩"; else glyph="→"; fi

    # Prepend space character to match badge
    if $use_badges; then glyph=" $glyph"; fi

    # Use bold glyph
    if $use_glyphs && $use_badges; then
        glyph="%{\033[1m%}$glyph%{\033[0m%}"
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

    if $include_bg; then
        printf "30;48;2;%s;%s;%s" "$r" "$g" "$b"
    else
        printf "2;%s;%s;%s" "$r" "$g" "$b"
    fi
}

make_label() {
    local content=$1
    local color=${2:-$color_global}

    # Prevent empty content
    if [[ -z $content ]]; then return 1; fi

    if $use_colors; then
        printf "%%{\033[38;%sm%%}" "$(hex_to_ansi "$color")"
    fi

    printf "%b" "$content"

    if $use_colors; then
        printf "%%{\033[0m%%}"
    fi
}

make_badge() {
    local content=$1
    local color=${2:-$color_global}
    local glyph_left glyph_right ansi_sequence

    # Prevent empty content
    if [[ -z $content ]]; then return 1; fi

    if $use_glyphs; then
        # Use NF rounded corners
        glyph_left=$glyph_badge_left
        glyph_right=$glyph_badge_right
    else
        # Use plain padding
        content=" $content "
    fi

    if $use_colors; then
        ansi_sequence=$(hex_to_ansi "$color" true)
    else
        # Reverse video
        ansi_sequence=7
    fi

    printf "%s" "$(make_label "$glyph_left" "$color")"
    printf "%%{\033[%sm%%}" "$ansi_sequence"
    printf "%b" "$content"
    printf "%%{\033[0m%%}"
    printf "%s" "$(make_label "$glyph_right" "$color")"
}


### Predicates

is_root() { [[ $EUID -eq 0 ]]; }

is_su() { [[ -n $LOGNAME && $USER != "$LOGNAME" ]]; }

is_ssh() { [[ -n "$SSH_CLIENT" ]]; }

is_console() { [[ -t 1 && $TERM == linux ]]; }

is_error() { [[ $1 -ne 0 && $1 -ne 130 ]]; }

is_git() { [[ -n $(get_git_project) ]]; }

# Get top-level repository name
get_git_project() {
    if ! command -v git > /dev/null 2>&1; then return 1; fi

    local git_root
    if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
        printf "%s" "${git_root##*/}"
    fi
}


### Hooks

# Prepend blank line except after startup or clear
__print_blank() { [[ -n $__was_printed ]] && echo; __was_printed=1; }

# The clear command should also reset the flag
alias clear="command clear; unset __was_printed"


### Initialize

config && init
