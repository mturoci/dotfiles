# Dotfiles

Personal dotfiles for tmux, kitty, and zsh configurations.

## Features

- **Tmux**: Custom key bindings, status bar, and plugin management via TPM
- **Kitty**: Custom theme (Calm Forest) and keyboard shortcuts
- **Zsh**: Oh-My-Zsh with Powerlevel10k theme, useful aliases, and plugins

## Prerequisites

- Git
- Zsh (will be installed if not present)
- Internet connection for downloading dependencies

## Installation

### Quick Install

Clone the repository and run the install script:

```bash
git clone https://github.com/mturoci/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### Install Options

- `--skip-packages`: Skip package installation and only setup configurations

```bash
./install.sh --skip-packages
```

## What Gets Installed

### macOS (via Homebrew)
- tmux
- kitty
- oh-my-zsh
- zsh-autosuggestions
- zsh-syntax-highlighting
- powerlevel10k

### Ubuntu/Debian (via apt)
- tmux
- kitty (from official installer)
- zsh
- oh-my-zsh
- zsh-autosuggestions
- zsh-syntax-highlighting
- powerlevel10k

## Post-Installation

1. **Restart your terminal** or run:
   ```bash
   source ~/.zshrc
   ```

2. **Install tmux plugins**: Open tmux and press `Ctrl+p` then `I` (capital i) to install plugins

3. **Configure Powerlevel10k**: Run `p10k configure` to customize your prompt

4. **Install fonts**: Install [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads) for proper icon rendering

## Configuration Files

- `tmux/.tmux.conf` - Tmux configuration
- `tmux/right_status.sh` - Tmux status bar script
- `kitty/kitty.conf` - Kitty terminal configuration
- `kitty/current-theme.conf` - Kitty color theme
- `zsh/.zshrc` - Zsh configuration

## Tmux Key Bindings

- **Prefix**: `Ctrl+p` (instead of default `Ctrl+b`)
- **Split horizontal**: `prefix + /`
- **Split vertical**: `prefix + -`
- **New window**: `prefix + c`
- **Kill window**: `prefix + q`
- **Kill pane**: `prefix + x`
- **Reload config**: `prefix + r`
- **Navigate panes**: `Alt+h/j/k/l`
- **Maximize pane**: `prefix + m`
- **Even layout vertical**: `Alt+-`
- **Even layout horizontal**: `Alt+/`

## Useful Aliases

### Git
- `g` - git
- `gst` - git status
- `grh` - git reset --hard
- `grs` - git reset --soft
- `gs` - git stash
- `gsp` - git stash pop

### Other
- `d` - docker
- `prj` - cd to projects directory

## Backup

The install script automatically backs up existing configuration files with a timestamp before creating symlinks.

## Uninstallation

To uninstall, simply remove the symlinks and restore your backups:

```bash
rm ~/.tmux.conf ~/.zshrc
rm -rf ~/.config/kitty/kitty.conf ~/.config/kitty/current-theme.conf
rm -rf ~/.tmux/right_status.sh
```

Then restore your backup files (if any) from `~/*.backup.*`

## License

MIT

## Author

Martin Turoci ([@mturoci](https://github.com/mturoci))
