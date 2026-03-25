# `>_` nix-prompt

**A clean, modular [Bash](#requirements) prompt with just the right amount of features.**

Designed to be **readable**, **hackable**, and **safe** to source in `.bashrc`.

No framework. No dependencies. No magic.

![nix-prompt preview](./preview/nixprompt.svg)

> [!NOTE]
> The preview image shows possible configurations of `nix-prompt` and is meant to demonstrate how the prompt can adapt to different contexts.
> It does not fully represent a single default configuration. Please read the [Configuration](#configuration) section for details.


## Features

### 🛠️ Modular Segments
Build your prompt by arranging segments: **Identity** (user/host/custom), **Timestamp**, **Path**, **Git Status**, and **Prompt Symbol**.

### 🎨 Modern Aesthetics
Enjoy a beautiful, highly readable terminal with **Truecolor support** and clean **Nerd Font icons**. Everything can be customized to match your colors.

### 👀 Context-Aware
The prompt automatically adapts to what you're doing:
- Distinct accent colors or symbols for **Root** vs **User**
- Prominent indicators for remote **SSH** sessions
- Blinking alerts for the **Last error state**
- Native **Git** status integration (`*`, `+`, `%` indicators)


## Requirements

- **Bash ≥ 4**, **Zsh**, or **Fish**
- **Git** (optional, for git segment)
- **Nerd Font** (recommended, for glyphs and rounded badges)

The preview above uses [JetBrainsMono Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip).

> [!NOTE]
> The script was primarily written for **Bash**, with care and attention to detail, love for the craft and the best practices in mind. The **Zsh** and **Fish** scripts are experimental adaptations mostly written by AI. I've chosen to include them for fun and testing purposes only.


## Installation

Before anything else, make sure your terminal uses a **Nerd Font** instead of a regular (non-patched) font. The glyphs are used to create those rounded badges and display some of the icons. Alternatively, the script can be configured to use fallbacks — check the [Configuration](#configuration) section a little lower.

### 1. Automatic (Recommended)

The easiest way to install `nix-prompt` is with the one-line installer.

```bash
curl -sS https://raw.githubusercontent.com/nix-tricks/nix-prompt/refs/heads/main/scripts/install.sh | bash
```

<details>
<summary><strong>What does the install script do? (Click to expand)</strong></summary>

- Detects your current shell (Bash, Zsh, or Fish)
- Downloads the specific script version to your home directory (`~/.nixprompt.[shell]`)
- Creates a backup if an older version exists
- Automatically sources it in your shell configuration file (`.bashrc`, `.zshrc`, or `config.fish`)

</details>

### 2. Manual Installation

If you prefer to manually download and source the files, choose your shell below:

<details>
<summary><strong>Bash</strong></summary>

1. Download [`scripts/nixprompt.sh`](scripts/nixprompt.sh) to your home directory as `.nixprompt.bash`.
2. Source it in your `~/.bashrc`:
   ```bash
   # Custom Bash prompt script from NIX tricks
   [ -f ~/.nixprompt.bash ] && source ~/.nixprompt.bash
   ```

</details>

<details>
<summary><strong>Zsh</strong></summary>

1. Download [`scripts/nixprompt.zsh`](scripts/nixprompt.zsh) to your home directory as `.nixprompt.zsh`.
2. Source it in your `~/.zshrc`:
   ```zsh
   # Custom Zsh prompt script from NIX tricks
   [ -f ~/.nixprompt.zsh ] && source ~/.nixprompt.zsh
   ```

</details>

<details>
<summary><strong>Fish</strong></summary>

1. Download [`scripts/nixprompt.fish`](scripts/nixprompt.fish) to your home directory as `.nixprompt.fish`.
2. Source it in your `~/.config/fish/config.fish`:
   ```fish
   # Custom Fish prompt script from NIX tricks
   test -f ~/.nixprompt.fish; and source ~/.nixprompt.fish
   ```

</details>

> [!TIP]
> Repeat the process for the **root user** to be able to use the alternate color scheme. Install on **remote hosts** and customize the colors in the script to be able to use the prompt via SSH.

*(Don't forget to **restart your terminal session** after installation!)*


## Nix / NixOS Integration

Although the project is called **nix-prompt**, it is **not** strictly tied to Nix or NixOS. The name originates from my YouTube channel, NIX tricks, referring to the broader Unix-like ecosystem.

However, if you *are* using Nix or NixOS, a community member has created a fantastic **Nix flake module** for simple interpolation through **Home Manager**:

🔗 [**rcouto/nix-prompt.nix**](https://gist.github.com/rcouto/bdb5794940647cf446841f305d65c486)

*Note: This integration is maintained externally and is purely optional, but it's an excellent choice if you're managing your environment declaratively via Nix.*


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

Customize these hex values to blend perfectly with your terminal theme:
| Variable | Default | Description |
|---|---|---|
| `color_primary` | `#f5992e` | Accent color for regular users (e.g. Identity badge) |
| `color_secondary` | `#785cea` | Accent color when running as **Root** |
| `color_neutral` | `#5f5f87` | Faded alternative tone for secondary segments like Git |

The *global* color is automatically selected depending on whether the shell is running as root.

> [!IMPORTANT]
> - The script must be installed for the **root user as well** if you want the alternate prompt to apear in root shells
> - It can be installed and customized on **remote machines**, if you want to use the prompt when you connect over SSH
> - Colors do not change dynamically. There is **no special color handling** to indicate error states aside from the glyph

### 3. Features

Easily toggle major aesthetic features on or off as booleans (`true`/`false`):

| Variable | Default | Description |
|---|---|---|
| `use_colors` | `true` | Allows prompt segments to be colored via Truecolor ANSI codes |
| `use_glyphs` | `true` | Uses Nerd Font icons. Set `false` to use regular ASCII symbols |
| `use_badges` | `true` | Enables rounded badge backgrounds. Set `false` for plain text |

### 4. Options

Additional environment variables used to style prompt metrics:

| Variable | Default | Description |
|---|---|---|
| `PROMPT_DIRTRIM` | `2` | Trailing directory components to show before truncating path |
| `GIT_PS1_SHOWUNTRACKEDFILES` | `1` | Show an indicator (`%`) when untracked files exist |
| `GIT_PS1_SHOWDIRTYSTATE` | `1` | Show indicators (`*` or `+`) for modified or staged files |


---

**How do I uninstall or disable it?**
Simply comment out or remove the source line from your shell configuration file. This prompt script modifies your `PS1`, `PS2`, and `PROMPT_COMMAND` (or `precmd_functions` in Zsh, or `fish_prompt` in Fish).
