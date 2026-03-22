#!/usr/bin/fish
# Copyright (c) 2026 NIX tricks
# Released under the MIT License
# SPDX-License-Identifier: MIT


### Setup

function _nixprompt_config
    # Define active features
    set -g use_colors true
    set -g use_glyphs true
    set -g use_badges true

    # Define custom colors
    set -g color_primary "f5992e"
    set -g color_secondary "785cea"
    set -g color_neutral "5f5f87"
    set -g color_global ""

    set -g glyph_badge_left ""
    set -g glyph_badge_right ""

    # Define main color
    if is_root
        set color_global $color_secondary
    else
        set color_global $color_primary
    end

    # Prevent NF glyphs on console sessions
    if is_console
        set use_glyphs false
    end

    set -g GIT_PS1_SHOWUNTRACKEDFILES 1
    set -g GIT_PS1_SHOWDIRTYSTATE 1
end


### Renderers

function render_identity
    set -l cmd_status $argv[1]
    set -l glyph
    set -l label

    # Define glyph
    if is_error $cmd_status
        if test "$use_glyphs" = true; set glyph ""; else; set glyph "!"; end
        # Add blinking effect to error state glyph
        set glyph "\e[5m$glyph\e[25m"
    else if is_ssh
        if test "$use_glyphs" = true; set glyph "󰌘"; else; set glyph "*"; end
    else if is_root
        if test "$use_glyphs" = true; set glyph ""; else; set glyph "#"; end
    else
        if test "$use_glyphs" = true; set glyph ""; else; set glyph "\$"; end
    end

    # Define label
    if is_ssh; or is_su
        set -l host (prompt_hostname)
        if test -z "$host"
            set host "$hostname"
        end
        set label "$USER@$host"
    else if is_git
        set label (get_git_project)
    else
        set label (prompt_hostname)
        if test -z "$label"
            set label "$hostname"
        end
    end

    # Global fallback to ensure identity is never empty
    if test -z "$label"
        set label "$USER"
    end

    # Rendering logic
    if test "$use_badges" = true
        make_badge "$glyph $label"
    else
        make_label "$glyph $label"
    end
end

function render_timestamp
    set -l label (date +%I:%M:%S)

    # Rendering logic
    if test "$use_badges" = true
        make_label "$label"
    else
        make_label "[$label]" "$color_neutral"
    end
end

function render_path
    set -l glyph ""
    set -l label (prompt_pwd)

    # Rendering logic
    if test "$use_glyphs" = true
        printf "%s %s" (make_label "$glyph") "$label"
    else
        printf "%s" "$label"
    end
end

function render_git
    set -l glyph ""
    set -l label "%s"

    # Prevent if not a repository
    if not is_git
        return
    end

    # Use brackets instead of badges
    if test "$use_badges" != true
        set label "($label)"
    end

    # Prepend glyph to label
    if test "$use_glyphs" = true
        set label "$glyph $label"
    end

    # Build format string
    set -l format
    if test "$use_badges" = true
        set format (make_badge "$label" "$color_neutral")
    else if test "$use_colors" = true
        set format (make_label "$label" "$color_secondary")
    else
        set format "$label"
    end

    # Get current branch or short hash
    set -l git_branch (
        git branch --show-current 2>/dev/null
        or git rev-parse --short HEAD 2>/dev/null
    )

    if test -z "$git_branch"
        return
    end

    # Build status indicators
    set -l git_status ""
    if test "$GIT_PS1_SHOWDIRTYSTATE" = 1
        git diff --quiet 2>/dev/null
        or set git_status "$git_status*"
        git diff --cached --quiet 2>/dev/null
        or set git_status "$git_status+"
    end

    if test "$GIT_PS1_SHOWUNTRACKEDFILES" = 1
        set -l untracked (
            git ls-files --others --exclude-standard 2>/dev/null
        )
        if test -n "$untracked"
            set git_status "$git_status%"
        end
    end

    if test -n "$git_status"
        set git_branch "$git_branch $git_status"
    end

    # Substitute %s with the git branch string
    printf "%s" (string replace "%s" "$git_branch" "$format")
end

function render_prompt
    set -l glyph

    # Define glyph
    if test "$use_glyphs" = true; and test "$use_badges" = true
        set glyph "󱞩"
    else
        set glyph "→"
    end

    # Prepend space character to match badge
    if test "$use_badges" = true
        set glyph " $glyph"
    end

    # Use bold glyph
    if test "$use_glyphs" = true; and test "$use_badges" = true
        set glyph "\e[1m$glyph\e[0m"
    end

    # Prepend newline character
    printf "\n%s" (make_label "$glyph")
end


### Helpers

function hex_to_ansi
    set -l hex (string replace -r "^#" "" $argv[1])
    set -l include_bg $argv[2]

    set -l r (math "0x"(string sub -s 1 -l 2 $hex))
    set -l g (math "0x"(string sub -s 3 -l 2 $hex))
    set -l b (math "0x"(string sub -s 5 -l 2 $hex))

    if test "$include_bg" = true
        printf "30;48;2;%s;%s;%s" $r $g $b
    else
    printf "2;%s;%s;%s" $r $g $b
    end

end

function make_label
    set -l content $argv[1]
    set -l color $argv[2]

    # Fall back to the global color
    if test -z "$color"
        set color $color_global
    end

    # Prevent empty content
    if test -z "$content"
        return
    end

    if test "$use_colors" = true
        printf "\e[38;%sm" (hex_to_ansi "$color")
    end

    printf "%b" "$content"

    if test "$use_colors" = true
        printf "\e[0m"
    end
end

function make_badge
    set -l content $argv[1]
    set -l color $argv[2]

    # Fall back to the global color
    if test -z "$color"
        set color $color_global
    end

    set -l glyph_left ""
    set -l glyph_right ""
    set -l ansi_sequence ""

    # Prevent empty content
    if test -z "$content"
        return
    end

    if test "$use_glyphs" = true
        # Use NF rounded corners
        set glyph_left $glyph_badge_left
        set glyph_right $glyph_badge_right
    else
        # Use plain padding
        set content " $content "
    end

    # Pick ANSI sequence: truecolor bg or reverse video
    set -l ansi
    if test "$use_colors" = true
        set ansi (hex_to_ansi "$color" true)
    else
        set ansi 7
    end

    make_label "$glyph_left" "$color"
    printf "\e[%sm%b\e[0m" "$ansi" "$content"
    make_label "$glyph_right" "$color"
end


### Predicates

function is_root
    test (id -u) -eq 0
end

function is_su
    test -n "$LOGNAME"; and test "$USER" != "$LOGNAME"
end

function is_ssh
    set -q SSH_CLIENT
end

function is_console
    test -t 1; and test "$TERM" = linux
end

function is_error
    set -l code $argv[1]
    test "$code" -ne 0 -a "$code" -ne 130
end

function is_git
    set -l project (get_git_project)
    test -n "$project"
end

# Get the top-level repository name
function get_git_project
    if not command -q git
        return
    end

    set -l root (git rev-parse --show-toplevel 2>/dev/null)
    and basename "$root"
end


### Hooks

# Print a blank line before each prompt (except after startup or clear)
function __print_blank --on-event fish_prompt
    if set -q __was_printed
        echo
    end
    set -g __was_printed 1
end

# Reset the blank-line flag when the screen is cleared
function clear
    command clear
    set -e __was_printed
end


### Initialize

function fish_prompt
    set -l last_status $status

    if not set -q _nixprompt_configured
        _nixprompt_config
        set -g _nixprompt_configured 1
    end

    set -l segments identity timestamp path git prompt
    for segment in $segments
        set -l renderer "render_$segment"
        if functions -q "$renderer"
            eval "$renderer $last_status"
            printf " "
        end
    end
end
