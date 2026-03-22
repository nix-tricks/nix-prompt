#!/bin/bash
set -e

USER_SHELL=$(ps -o comm= -p "$PPID" 2>/dev/null | awk '{print $1}')
USER_SHELL=$(basename "$USER_SHELL")
USER_SHELL=${USER_SHELL#-}

BASE_URL="https://raw.githubusercontent.com/nix-tricks/nix-prompt/refs/heads/main/scripts"

if [ "$USER_SHELL" = "zsh" ]; then
    FILE_EXT="zsh"
    RC_FILE="$HOME/.zshrc"
    RC_INJECT="[ -f ~/.nixprompt.${USER_SHELL} ] && source ~/.nixprompt.${USER_SHELL}"
elif [ "$USER_SHELL" = "fish" ]; then
    FILE_EXT="fish"
    RC_FILE="$HOME/.config/fish/config.fish"
    RC_INJECT="test -f ~/.nixprompt.${USER_SHELL}; and source ~/.nixprompt.${USER_SHELL}"
else
    FILE_EXT="sh"
    RC_FILE="$HOME/.bashrc"
    RC_INJECT="[ -f ~/.nixprompt.${USER_SHELL} ] && source ~/.nixprompt.${USER_SHELL}"
fi

REMOTE_URL="${BASE_URL}/nixprompt.${FILE_EXT}"

LOCAL_FILE="$HOME/.nixprompt.${USER_SHELL}"

# Download the prompt file
printf "Downloading %s prompt...\n" "$USER_SHELL"

# Backup existing prompt file if it exists
if [ -f "$LOCAL_FILE" ]; then
    printf "Backing up .nixprompt.%s to .nixprompt.%s.bak\n" "$USER_SHELL" "$USER_SHELL"
    mv "$LOCAL_FILE" "$LOCAL_FILE.bak"
fi

if command -v curl &> /dev/null; then
    curl -fsSL "$REMOTE_URL" -o "$LOCAL_FILE"
elif command -v wget &> /dev/null; then
    wget -q "$REMOTE_URL" -O "$LOCAL_FILE"
else
    printf "Error: Neither curl nor wget found."
    exit 1
fi

# Add source lines to rc file if they don't already exist
if ! grep -qF "$RC_INJECT" "$RC_FILE" 2>/dev/null; then
    # Make sure rc file directory exists
    mkdir -p "$(dirname "$RC_FILE")"

    # Remove all trailing newlines
    if [ -f "$RC_FILE" ]; then
        printf %s "$(cat "$RC_FILE")" > "$RC_FILE"
    fi

    printf "\n\n# Custom %s prompt script from NIX tricks" "$USER_SHELL" >> "$RC_FILE"
    printf "\n%s\n\n" "$RC_INJECT" >> "$RC_FILE"
    printf "Installation complete. Restart your terminal.\n"
else
    printf "Already installed.\n"
fi
