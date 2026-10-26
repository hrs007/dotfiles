# Dotfiles

Personal configuration files managed in one repository. Each directory contains the configuration and setup notes for a tool or environment.

## Configurations

- [`nvim/`](nvim/) — Neovim configuration for terminal Neovim and Neovide. See [`nvim/README.md`](nvim/README.md) for installation, platform setup, dependencies, and troubleshooting.
- [`bash/.bashrc`](bash/.bashrc) — Bash startup configuration symlink.
- [`tmux/.tmux.conf`](tmux/.tmux.conf) — tmux configuration. The file is a symbolic link to `~/.tmux.conf`, so edits to the home-directory config are reflected here.
- [`zsh/.zshrc`](zsh/.zshrc) — Zsh shell startup configuration, linked to `~/.zshrc`.
- [`vim/.vimrc`](vim/.vimrc) — Cross-platform Vim configuration, linked to `~/.vimrc` on macOS and Linux or `_vimrc` on Windows.

## Linking Zsh and Vim configurations

The Zsh and Vim configs are symbolic links into this repository. To recreate them after cloning, move any existing files aside first, then run:

```sh
ln -s ~/dotfiles/zsh/.zshrc ~/.zshrc
ln -s ~/dotfiles/vim/.vimrc ~/.vimrc
```

For Bash, link your home-directory config into the cloned repository, then edit it as usual:

```sh
ln -sfn "$HOME/.bashrc" "$HOME/dotfiles/bash/.bashrc"
nvim "$HOME/.bashrc"
```

The `-f` option replaces the repository's existing Bash symlink if needed. The commands work on Linux and macOS, assuming the repository is cloned to `~/dotfiles`.

On Windows, create a directory junction or copy `vim/.vimrc` to `$HOME\_vimrc`. The config detects Windows paths and uses `$LOCALAPPDATA\vim\undo` for persistent undo files. Clipboard integration is enabled only when Vim was built with clipboard support.

## Linking tmux configuration

The tmux config is linked into this repository so it can be tracked alongside the other dotfiles. To recreate the link on a machine after cloning:

```sh
mkdir -p ~/dotfiles/tmux
ln -s ~/.tmux.conf ~/dotfiles/tmux/.tmux.conf
```

If `~/dotfiles/tmux/.tmux.conf` already exists, move it aside before creating the link. To use the tracked config as the active tmux config on a new machine, link it from your home directory:

```sh
ln -s ~/dotfiles/tmux/.tmux.conf ~/.tmux.conf
```
