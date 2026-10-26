# Dotfiles

Personal configuration files for shells, editors, and tmux. The repository is designed to live at `~/dotfiles`. Shell and Vim files are kept in your home directory and linked into the repository; the Neovim configuration is stored in the repository and linked into Neovim's config directory.

## What's included

- [`bash/.bashrc`](bash/.bashrc) — Bash startup configuration symlink.
- [`zsh/.zshrc`](zsh/.zshrc) — Zsh startup configuration symlink.
- [`vim/.vimrc`](vim/.vimrc) — Vim configuration symlink.
- [`tmux/.tmux.conf`](tmux/.tmux.conf) — tmux configuration symlink.
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

Clone the repository into your home directory. These commands make the repository entries point to your home config files. Move any existing home configs you want to keep into place first; skip links for tools you do not use.

```sh
git clone https://github.com/hrs007/dotfiles.git "$HOME/dotfiles"
mkdir -p "$HOME/dotfiles/bash" "$HOME/dotfiles/zsh" "$HOME/dotfiles/vim" "$HOME/dotfiles/tmux"
mkdir -p "$HOME/.config"
ln -sfn "$HOME/.bashrc" "$HOME/dotfiles/bash/.bashrc"
ln -sfn "$HOME/.zshrc" "$HOME/dotfiles/zsh/.zshrc"
ln -sfn "$HOME/.vimrc" "$HOME/dotfiles/vim/.vimrc"
ln -sfn "$HOME/.tmux.conf" "$HOME/dotfiles/tmux/.tmux.conf"
ln -sfn "$HOME/dotfiles/nvim" "$HOME/.config/nvim"
```

Create any home config files that do not exist before linking them. On macOS, Bash login shells start with `~/.bash_profile`; make it load `.bashrc` if needed by adding this line to `~/.bash_profile`:

```sh
[[ -f "$HOME/.bashrc" ]] && source "$HOME/.bashrc"
```

Start Neovim and run `:Lazy sync` to install plugins. For Neovide and Neovim language tools, follow the platform-specific guide in [`nvim/README.md`](nvim/README.md).

## Windows setup

Install Git for Windows for Git Bash. In Git Bash, clone the repo and link the Bash startup file:

```sh
git clone https://github.com/hrs007/dotfiles.git "$HOME/dotfiles"
ln -sfn "$HOME/.bashrc" "$HOME/dotfiles/bash/.bashrc"
```

Create or edit `$HOME/.bashrc` in Git Bash. Windows Git may check out symbolic links as text unless symlink support is enabled; enable Windows Developer Mode or use an elevated Git Bash when creating links. PowerShell does not load Bash or Zsh startup files.

For Neovim, install it with `winget install --id Neovim.Neovim -e`, then in PowerShell link the config directory:

```powershell
git clone https://github.com/hrs007/dotfiles.git $HOME\dotfiles
New-Item -ItemType Directory -Force "$env:LOCALAPPDATA" | Out-Null
New-Item -ItemType Junction -Path "$env:LOCALAPPDATA\nvim" -Target "$HOME\dotfiles\nvim"
```

If the repository is already cloned, skip the `git clone` command. If the destination config already exists, move it aside before creating the link. See [`nvim/README.md`](nvim/README.md) for Neovim plugin, language tool, and Neovide setup details.
