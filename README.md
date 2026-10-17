# Neovim dotfiles

Personal Neovim configuration for terminal Neovim and [Neovide](https://neovide.dev/), with setup helpers for macOS and Windows. The configuration uses Lua, [lazy.nvim](https://github.com/folke/lazy.nvim) for plugins, and Mason for language servers, formatters, and debuggers.

## What's included

- Plugin and editor configuration in [`nvim/`](nvim/)
- A [`lazy-lock.json`](nvim/lazy-lock.json) lockfile to keep plugin versions consistent
- Automatic bootstrap of `lazy.nvim` on first launch
- Automatic installation of configured language servers, formatters, and debuggers through Mason
- A macOS Neovide setup script and a Windows **Open with** registration script

## macOS setup

### 1. Install the applications and font

Install [Homebrew](https://brew.sh/) if you do not already have it, then install Neovim, Neovide, Git, and the Nerd Font used by the Neovide configuration:

```sh
brew install git neovim
brew install --cask neovide-app font-jetbrains-mono-nerd-font
```

The Nerd Font is optional for terminal use, but recommended for plugin icons. Neovide is also optional if you only use Neovim in a terminal.

### 2. Clone this repository and link the Neovim configuration

```sh
git clone https://github.com/hrs007/dotfiles.git ~/dotfiles
mkdir -p ~/.config
ln -s ~/dotfiles/nvim ~/.config/nvim
```

If `~/.config/nvim` already exists, move it aside before creating the link. This link lets Neovim read the configuration from the cloned repository.

### 3. Start Neovim and install plugins

```sh
nvim
```

On first launch, the config bootstraps `lazy.nvim` and installs plugins. When startup completes, run `:Lazy sync` to make sure everything is installed. Mason will install the configured language servers, formatters, and debug adapters; open `:Mason` to inspect them. Some tools may need to finish downloading before they are ready.

### 4. Configure Neovide (optional)

Run the setup script from the repository:

```sh
cd ~/dotfiles
./scripts/macos/configure-neovide.sh
```

The script points Neovide to the `nvim` executable on your `PATH`, enables a maximized window, selects JetBrains Mono Nerd Font, and configures Finder defaults for common Python, JavaScript, C, and C++ files when possible. It does not install Neovide or Neovim; install them in step 1 first.

For `.ts` and `.tsx` files, if another app is already the default, select a file in Finder, press **Command-I**, choose **Neovide** under **Open with**, and click **Change All**.

## Windows setup

Install Neovim and Neovide first. Then clone this repository and link or copy its `nvim` folder to Neovim's configuration directory (`%LOCALAPPDATA%\nvim`). For example, in PowerShell:

```powershell
git clone https://github.com/hrs007/dotfiles.git $HOME\dotfiles
New-Item -ItemType Directory -Force "$env:LOCALAPPDATA" | Out-Null
New-Item -ItemType Junction -Path "$env:LOCALAPPDATA\nvim" -Target "$HOME\dotfiles\nvim"
```

If `%LOCALAPPDATA%\nvim` already exists, move it aside before creating the junction. Start Neovim once to bootstrap plugins, then run `:Lazy sync`.

To register Neovide under **Open with** for common programming and configuration file extensions, open PowerShell in the repository and run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\Register-NeovideOpenWith.ps1
```

The script configures Neovide's Neovim executable and opens Windows Default Apps settings. Choose Neovide for the extensions you want; Windows may require you to set defaults in Settings. To remove the registration, run the script with `-Unregister`.

## Language tools and optional dependencies

Mason installs the language support configured in this repository, including servers for Python, C/C++, JavaScript/TypeScript, HTML/CSS, Tailwind, JSON, YAML, Lua, XML, and XAML. It also installs configured formatters and debug adapters. You do not need to install each server separately.

Install the relevant system tools for languages and workflows you use:

| Use | Install | Why |
| --- | --- | --- |
| C and C++ | macOS: `xcode-select --install` | Provides a compiler and build tools; useful for Tree-sitter parsers and native plugins. |
| Python | Python 3 | Runs Python projects and their virtual environments. |
| JavaScript and TypeScript | Node.js and npm | Runs JS/TS projects and their package scripts. |
| C# and .NET | .NET SDK | Builds, runs, and tests .NET projects; needed for the C# workflow. |
| Git UI | [lazygit](https://github.com/jesseduffield/lazygit) | Used by the configured LazyGit integration. |
| Neovide icons | JetBrains Mono Nerd Font | Used by the Neovide font setting and recommended for icons in other UIs. |

On macOS, install these with Homebrew as needed. For example:

```sh
brew install python node dotnet lazygit
```

Then install Xcode Command Line Tools separately with `xcode-select --install`. On Windows, install the corresponding tools from their official installers or package manager. These dependencies are optional unless you use the associated language or feature.

## Troubleshooting

- Run `:Lazy sync` to install or update plugins.
- Run `:Mason` to inspect language servers and tools managed by Mason.
- If icons are missing in Neovide, install JetBrains Mono Nerd Font and restart Neovide.
- If the Neovide script cannot find Neovim, confirm `nvim` is on your `PATH`, then rerun the script.
- Check `:checkhealth` for Neovim environment diagnostics.
