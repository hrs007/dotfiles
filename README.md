# dotfiles

## Open source files in Neovide

Neovide is a GUI front end for the Neovim configuration in this repository. Install Neovide and Neovim first, then run the setup for your operating system. The Windows script registers common programming and configuration file extensions for **Open with**; neither setup claims every text file.

### macOS

Install Neovide and Neovim, then run:

```sh
./scripts/macos/configure-neovide.sh
```

This configures Neovide at `$XDG_CONFIG_HOME/neovide/config.toml` (or `~/.config/neovide/config.toml`) to use Homebrew's Neovim binary, start maximized, and use the installed JetBrains Mono Nerd Font. It also sets Finder defaults for common Python, JavaScript, C, and C++ extensions. The shared Neovim config disables Neovide-only cursor, scroll, and floating-window effects while keeping the same plugins and panels.

For `.ts` or `.tsx` files currently claimed by another app, select a file in Finder, press **Command-I**, choose **Neovide** under **Open with**, and click **Change All**. Repeat for each extension you want to open in Neovide.

### Windows

Install Neovide and Neovim (Scoop is one option), open PowerShell in this repository, then run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\Register-NeovideOpenWith.ps1
```

This registers Neovide under **Open with** for common programming and configuration extensions, configures its Neovim binary, and opens Windows Default Apps settings. Select Neovide there for each extension you want. Recent Windows versions protect default-app selection, so the script intentionally does not force a default association. Re-run the script with `-Unregister` to remove its Open with registration.
