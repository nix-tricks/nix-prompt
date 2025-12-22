#!/bin/bash

set -e

REMOTE_URL="https://raw.githubusercontent.com/nix-tricks/nix-prompt/refs/heads/main/scripts/nixprompt.sh"
LOCAL_FILE="$HOME/.nixprompt"
BASHRC="$HOME/.bashrc"

# Download the prompt file
printf "Downloading prompt...\n"

# Backup existing prompt file if it exists
if [ -f "$LOCAL_FILE" ]; then
    printf "Backing up .nixprompt to .nixprompt.bak\n"
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

# Add source lines to .bashrc if they don't already exist
if ! grep -qF "[ -f ~/.nixprompt ] && source ~/.nixprompt" "$BASHRC" 2>/dev/null; then
    # Remove all trailing newlines from .bashrc
    printf %s "$(cat "$BASHRC")" > "$BASHRC"

    printf "\n\n# Custom bash prompt script from NIX tricks" >> "$BASHRC"
    printf "\n[ -f ~/.nixprompt ] && source ~/.nixprompt\n\n" >> "$BASHRC"
    printf "Installation complete. Restart your terminal.\n"
else
    printf "Already installed.\n"
fi
