# `>_` nix-prompt

**A clean, modular Bash prompt with just the right amount of features.**

Designed to be **readable**, **hackable**, and **safe** to source in `.bashrc`.

No framework. No dependencies. No magic.

![nix-prompt preview](./preview/nixprompt.svg)

> [!NOTE]
> The preview image shows possible configurations of `nix-prompt` and is meant to demonstrate how the prompt can adapt to different contexts.
> It does not fully represent a single default configuration. Please read the [Configuration](#configuration) section for details.


## Features

### 🛠️ Modular segments

- Identity (user / host / context)
- Timestamp
- Path
- Git status
- Prompt symbol


### 🎨 Modern aesthetics

- Truecolor support
- Nerd Font icons


### 👀 Context-aware

- Root vs user
- SSH sessions
- Last error state
- Git integration


## Requirements

- Bash ≥ 4
- Git (optional, for git segment)
- Nerd Font (recommended, for glyphs and rounded badges)

The preview above uses [JetBrainsMono Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip).


## Installation

Before anything else, make sure your terminal uses a Nerd Font instead of a regular (non-patched) font. The glyphs are used to create those rounded corner badges and display most of the icons. Alternatively, the script can be configured to use fallbacks — check the [Configuration](#configuration) section a little lower.

### Automatic method

Just copy and paste this one-liner:

```bash
curl -sS https://raw.githubusercontent.com/nix-tricks/nix-prompt/refs/heads/main/scripts/install.sh | bash
```

This is what the install script does:
- Downloads the appropriate script to your home directory as `.nixprompt.[shell]`
- Creates a backup of any existing file with that name
- Sources the appropriate script in `.bashrc` or `.zshrc` (if not already sourced)

### Manual method

If you want to manually install the prompt script for Bash:
- Download the script `scripts/nixprompt.sh` to your home directory as an executable file named `.nixprompt.bash`
- Source it in `.bashrc` by adding something like: `[ -f ~/.nixprompt.bash ] && source ~/.nixprompt.bash`

If you want to manually install the prompt script for Zsh:
- Download the script `scripts/nixprompt.zsh` to your home directory as an executable file named `.nixprompt.zsh`
- Source it in `.zshrc` by adding something like: `[ -f ~/.nixprompt.zsh ] && source ~/.nixprompt.zsh`
3. Restart the terminal session to see the changes
4. Repeat for the root user and other users (local & remote)


## Nix / NixOS integration (community)

Although the project is called **nix-prompt**, it is **not** specific to Nix or NixOS. The name comes from my YouTube channel, NIX tricks, where "nix" is used in the broader Unix-like sense. The prompt itself is written for **Bash** and is intended to work on any Linux or Unix-like system. That said, if you *are* using Nix or NixOS, this gist from a community member might just be what you're looking for:

- [rcouto/nix-prompt.nix](https://gist.github.com/rcouto/bdb5794940647cf446841f305d65c486)

This is a **Nix flake module** that makes it easy to integrate `nix-prompt` into a Nix-based setup using **Home Manager**. This integration is maintained externally and is not required to use `nix-prompt`, but it's a great option if you're managing your environment with Nix.


## Configuration

**All configuration is centralized in the `config()` function.**

The first function in the script is `config()` and it can be modified to add, remove or reorder prompt segments, change the colors, toggle prompt features or configure other options related to git or the shell.

### 1. Segments

**Segments are rendered in order**

```bash
segments=(identity timestamp path git prompt)
```

The `segments` variable defines an array of segments that are to be rendered in the specified order. A render function corresponds to each segment (e.g. `render_identity` for the `identity` segment) and each renderer is called by the `init()` function.

**Some segments are evaluated dynamically on each prompt redraw**

```bash
dynamics=(identity git)
```

The `dynamics` variable is for segments with renderers that need to be evaluated every time the prompt is rendered (e.g. the `identity` and `git` segments). Dynamic renderers cannot rely on Bash's backslash-escaped prompt expansions (such as `\w` or `\h`), since they are evaluated via command substitution.

### 2. Colors

There are three color variables that can be customized using hex values:

```bash
color_primary="#f5992e"   # accent for regular users (e.g. identity)
color_secondary="#785cea" # is the same as the above but for root
color_neutral="#5f5f87"   # is used as a faded alternative (e.g. git)
```

The global color is automatically selected depending on whether the shell is running as root.

A few things to keep in mind:

- The script must be installed for the **root user as well** if you want the prompt (and alternate color scheme) to apear in root shells
- It can be installed on **remote machines**, so that when you connect over SSH, the prompt may use the remote configuration
- There is **no special color handling for error states**. Aside from the exit-status indicator, colors are not changed dynamically

### 3. Features

There are three variables that can be used to toggle some of the features:

```bash
use_colors=true # can be turned off to use the default foreground color
use_icons=true  # can be turned off to replace NF glyphs with symbols
use_badges=true # can be turned off to remove the segment backgrounds
```

### 4. Options

There are three environment variables related to prompt configuration:

```bash
PROMPT_DIRTRIM=2 # sets the number of trailing directory components
GIT_PS1_SHOWUNTRACKEDFILES=1 # controls the untracked files indicator
GIT_PS1_SHOWDIRTYSTATE=1 # controls the dirty state indicator display
```


---

**Note:** This prompt script modifies your `PS1`, `PS2`, and `PROMPT_COMMAND` (or `precmd_functions` in Zsh) environment variables. To revert to your original prompt, simply comment out or remove the source line from your `.bashrc` or `.zshrc` file.
