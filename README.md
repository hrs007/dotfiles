# Dotfiles

Personal configuration files managed in one repository. Each directory contains the configuration and setup notes for a tool or environment.

## Configurations

- [`nvim/`](nvim/) — Neovim configuration for terminal Neovim and Neovide. See [`nvim/README.md`](nvim/README.md) for installation, platform setup, dependencies, and troubleshooting.
- [`tmux/.tmux.conf`](tmux/.tmux.conf) — tmux configuration. The file is a symbolic link to `~/.tmux.conf`, so edits to the home-directory config are reflected here.

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
