# Neovim dotfiles

Personal Neovim configuration for terminal Neovim and [Neovide](https://neovide.dev/), with setup helpers for macOS, Windows, and WSL Ubuntu. The configuration uses Lua, [lazy.nvim](https://github.com/folke/lazy.nvim) for plugins, and Mason for language servers, formatters, and debuggers.

## What's included

- Plugin and editor configuration in this directory
- A `lazy-lock.json` lockfile to keep plugin versions consistent
- Automatic bootstrap of `lazy.nvim` on first launch
- Automatic installation of configured language servers, formatters, and debuggers through Mason
- A macOS Neovide setup script and a Windows **Open with** registration script
- WSL clipboard integration through Windows `clip.exe` and `powershell.exe`

## macOS setup

### 1. Install the applications and font

Install [Homebrew](https://brew.sh/) if you do not already have it, then install Neovim, Neovide, Git, search tools (ripgrep and fd), and the Nerd Font used by the Neovide configuration:

```sh
brew install git neovim tree-sitter-cli ripgrep fd
brew install --cask neovide-app font-jetbrains-mono-nerd-font
xcode-select --install
```

Tree-sitter CLI **0.26.1 or newer** and a C compiler are required for this config to install its Tree-sitter parsers. `tree-sitter-cli` provides the `tree-sitter` command; Xcode Command Line Tools provide the compiler on macOS. The Nerd Font is optional for terminal use, but recommended for plugin icons. Neovide is also optional if you only use Neovim in a terminal.

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

## WSL Ubuntu setup

Run these commands in Ubuntu. Install Neovim and the common native tools inside WSL so plugins, language servers, and project commands use Linux executables:

```sh
sudo apt update
sudo apt install neovim git curl build-essential ripgrep fd-find unzip xclip nodejs npm python3-venv cargo
git clone https://github.com/hrs007/dotfiles.git ~/dotfiles
mkdir -p ~/.config
ln -s ~/dotfiles/nvim ~/.config/nvim
export PATH="$HOME/.cargo/bin:$PATH"
cargo install tree-sitter-cli --locked
nvim
```

If `~/.config/nvim` already exists, move it aside before creating the link. Run `:Lazy sync` after the first launch. `nodejs` provides the Node executable for the JavaScript debugger. `cargo install` installs Tree-sitter CLI; add `export PATH="$HOME/.cargo/bin:$PATH"` to `~/.bashrc` so Neovim can find it in future sessions. Ubuntu packages `fd` as `fdfind`; if Telescope cannot find `fd`, install the `fd` package if available for your Ubuntu release or add an `fd` symlink to `fdfind` in `~/.local/bin`.

If Mason reports the debugpy interpreter missing, open Neovim and reinstall its Linux package:

```vim
:MasonUninstall debugpy
:MasonInstall debugpy
```

Restart Neovim after the install completes. If the Tree-sitter warning remains, check `tree-sitter --version`, `gcc --version`, `curl --version`, and `tar --version`; the parser installer needs Tree-sitter CLI 0.26.1 or newer plus those tools.

If the JavaScript debugger still reports Node.js missing, install Node.js and verify that Ubuntu can find it:

```sh
sudo apt install nodejs npm
node --version || nodejs --version
```

Restart Neovim after installation. The config checks both `node` and `nodejs` on `PATH`.

When running under WSL, the config uses Windows clipboard interop (`clip.exe` and `powershell.exe`) automatically when both commands are on `PATH`. This works for terminal Neovim without a Linux desktop clipboard. Windows interop must be enabled in WSL; otherwise install/use a Linux clipboard provider such as `xclip` when your terminal supports it. Keep active projects in the Linux filesystem (for example, `~/src`) for better filesystem performance; `/mnt/c` is available when you need to edit Windows files.

Neovide is optional; the instructions above set up terminal Neovim. GUI Neovide setup is separate from the WSL configuration.

## Language tools and optional dependencies

Mason installs the language support configured in this repository, including servers for Python, C/C++, JavaScript/TypeScript, HTML/CSS, Tailwind, JSON, YAML, Lua, XML, and XAML. It also installs configured formatters and debug adapters. You do not need to install each server separately.

Install the relevant system tools for languages and workflows you use:

| Use | Install | Why |
| --- | --- | --- |
| Tree-sitter parsers | Tree-sitter CLI 0.26.1+ and a C compiler | The config installs parser grammars automatically when these are available. On macOS, use `brew install tree-sitter-cli` and `xcode-select --install`. |
| C and C++ | macOS: `xcode-select --install` | Provides a compiler and build tools for C/C++ projects, Tree-sitter parsers, and native plugins. |
| Python | Python 3 | Runs Python projects and their virtual environments. |
| JavaScript and TypeScript | Node.js and npm | Runs JS/TS projects and their package scripts. |
| C# and .NET | .NET SDK | Builds, runs, and tests .NET projects; needed for the C# workflow. |
| Git UI | [lazygit](https://github.com/jesseduffield/lazygit) | Used by the configured LazyGit integration. |
| Search and navigation | [ripgrep](https://github.com/BurntSushi/ripgrep) and [fd](https://github.com/sharkdp/fd) | Required by Telescope for live text search (`<leader>fg`, `<leader>fw`) and fast file finding. |
| Neovide icons | JetBrains Mono Nerd Font | Used by the Neovide font setting and recommended for icons in other UIs. |

On macOS, install the language and workflow tools you need with Homebrew. For example:

```sh
brew install python node dotnet lazygit
```

On Windows, install the corresponding tools from their official installers or package manager. These dependencies are optional unless you use the associated language or feature.

On Ubuntu/WSL, install the tools you use with `apt` (for example `sudo apt install python3 nodejs npm dotnet-sdk-8.0 lazygit`). Package versions vary by Ubuntu release; use the relevant upstream installation instructions if a package is unavailable or too old.

On Windows, install Tree-sitter CLI 0.26.1 or newer and make sure a C compiler, `curl`, and `tar` are available on `PATH` for automatic parser installation. Restart Neovim after installing them.

## Troubleshooting

- Run `:Lazy sync` to install or update plugins.
- Run `:Mason` to inspect language servers and tools managed by Mason.
- If icons are missing in Neovide, install JetBrains Mono Nerd Font and restart Neovide.
- If the Neovide script cannot find Neovim, confirm `nvim` is on your `PATH`, then rerun the script.
- Check `:checkhealth` for Neovim environment diagnostics.
