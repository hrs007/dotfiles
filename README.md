# Dotfiles

Personal configuration files for shells, editors, and tmux. The repository is the source of truth and is designed to live at `~/dotfiles`. The `.bashrc`, `.zshrc`, `.vimrc`, and `.tmux.conf` files are tracked directly here. The Neovim configuration is also stored here and linked into Neovim's config directory.

## What's included

- [`bash/.bashrc`](bash/.bashrc) — Bash startup configuration.
- [`zsh/.zshrc`](zsh/.zshrc) — Zsh startup configuration.
- [`vim/.vimrc`](vim/.vimrc) — Vim configuration.
- [`tmux/.tmux.conf`](tmux/.tmux.conf) — tmux configuration.
- [`nvim/`](nvim/) — Neovim configuration. See [`nvim/README.md`](nvim/README.md) for Neovim-specific dependencies, platform setup, and troubleshooting.

## Dependencies

Git is needed to clone the repository. Install only the tools you plan to use; Neovim plugins and language tools have additional optional dependencies listed in [`nvim/README.md`](nvim/README.md).

| Platform | Install commands | Notes |
| --- | --- | --- |
| macOS | `brew install git bash zsh tmux neovim` | Install [Homebrew](https://brew.sh/) first. Vim is included with macOS; install `vim` with Homebrew if you want a newer version. |
| Debian or Ubuntu | `sudo apt update && sudo apt install git bash zsh tmux neovim vim` | Neovim is optional if you only use Vim. |
| Fedora | `sudo dnf install git bash zsh tmux neovim vim` | Neovim and Vim are optional if you only use shell configs. |
| Arch Linux | `sudo pacman -S git bash zsh tmux neovim vim` | Neovim and Vim are optional if you only use shell configs. |
| Windows | Install [Git for Windows](https://git-scm.com/download/win); optionally run `winget install --id Neovim.Neovim -e`. | Git for Windows includes Git Bash. Bash config applies in Git Bash; PowerShell does not read `.bashrc`. |

## macOS and Linux setup

Clone the repository into your home directory. The shell, Vim, and tmux config files live inside the repository, so source them from there or copy them to the home paths expected by each tool. Back up any existing home configs before replacing them. Skip setup for tools you do not use.

```sh
git clone https://github.com/hrs007/dotfiles.git "$HOME/dotfiles"
mkdir -p "$HOME/dotfiles/bash" "$HOME/dotfiles/zsh" "$HOME/dotfiles/vim" "$HOME/dotfiles/tmux"
mkdir -p "$HOME/.config"
cp "$HOME/dotfiles/bash/.bashrc" "$HOME/.bashrc"
cp "$HOME/dotfiles/zsh/.zshrc" "$HOME/.zshrc"
cp "$HOME/dotfiles/vim/.vimrc" "$HOME/.vimrc"
cp "$HOME/dotfiles/tmux/.tmux.conf" "$HOME/.tmux.conf"
ln -sfn "$HOME/dotfiles/nvim" "$HOME/.config/nvim"
```

The copy commands above replace existing home config files, so back them up first if needed. To keep home copies in sync after editing, copy the updated repository file again. On macOS, Bash login shells start with `~/.bash_profile`; make it load `.bashrc` if needed by adding this line to `~/.bash_profile`:

```sh
[[ -f "$HOME/.bashrc" ]] && source "$HOME/.bashrc"
```

Start Neovim and run `:Lazy sync` to install plugins. For Neovide and Neovim language tools, follow the platform-specific guide in [`nvim/README.md`](nvim/README.md).

## Windows setup

Install Git for Windows for Git Bash. In Git Bash, clone the repo and copy the Bash startup file into your home directory:

```sh
git clone https://github.com/hrs007/dotfiles.git "$HOME/dotfiles"
cp "$HOME/dotfiles/bash/.bashrc" "$HOME/.bashrc"
```

Back up any existing Bash config before replacing it with the repository copy. PowerShell does not load Bash or Zsh startup files.

For Neovim, install it with `winget install --id Neovim.Neovim -e`, then in PowerShell link the config directory:

```powershell
git clone https://github.com/hrs007/dotfiles.git $HOME\dotfiles
New-Item -ItemType Directory -Force "$env:LOCALAPPDATA" | Out-Null
New-Item -ItemType Junction -Path "$env:LOCALAPPDATA\nvim" -Target "$HOME\dotfiles\nvim"
```

If the repository is already cloned, skip the `git clone` command. If the destination config already exists, move it aside before creating the link. See [`nvim/README.md`](nvim/README.md) for Neovim plugin, language tool, and Neovide setup details.
