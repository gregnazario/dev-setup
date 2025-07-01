# Universal Installer Setup Script

A cross-platform installation script that automatically detects your platform and package manager, then sets up the Universal Installer tools.

## Features

- **Cross-platform support**: macOS, Linux, FreeBSD, NetBSD, Windows
- **Native package manager detection**: Uses existing package managers instead of installing new ones
- **TOML configuration**: Define package groups for easy development environment setup
- **Shell completions**: Automatic completion for bash, zsh, and fish
- **Manpage**: Comprehensive documentation accessible via `man universal-install`
- **Dry-run mode**: Preview installation without making changes
- **Security**: SHA256 checksum verification for downloads

## Quick Start

```bash
# Basic installation
./install.sh

# Install with completions and manpage
./install.sh --install-completions --install-manpage

# List available package groups
./install.sh --list-groups

# Install development tools
./install.sh --install-group development

# Install multiple groups
./install.sh --install-group development,python,nodejs

# Use custom configuration
./install.sh --config custom.toml --install-group minimal

# Preview what would be installed
./install.sh --dry-run

# Show help
./install.sh --help
```

## Supported Platforms

### macOS
- Uses Homebrew (installed automatically if needed)

### Linux
Supports 50+ distributions with their native package managers:

- **Debian-based**: apt (Ubuntu, Debian, Linux Mint, Pop!_OS, Elementary OS, Kali Linux, Parrot OS, MX Linux, Devuan, Deepin, Zorin OS)
- **Red Hat-based**: dnf/yum (Fedora, RHEL, CentOS, Rocky Linux, AlmaLinux, Oracle Linux, Amazon Linux, Scientific Linux)
- **Arch-based**: pacman (Arch Linux, Manjaro, EndeavourOS, Garuda Linux, ArcoLinux, Artix Linux)
- **SUSE-based**: zypper (openSUSE, SUSE Linux Enterprise, Tumbleweed, Leap)
- **Alpine**: apk (Alpine Linux)
- **Gentoo**: emerge (Gentoo, Funtoo, Calculate Linux)
- **Void**: xbps (Void Linux)
- **NixOS**: nix (NixOS)
- **Slackware**: slackpkg (Slackware, Slax, Salix)
- **Solus**: eopkg (Solus)
- **Clear Linux**: swupd (Intel Clear Linux)
- **PCLinuxOS**: apt-get (PCLinuxOS)
- **Mageia**: urpmi (Mageia)
- **OpenMandriva**: dnf (OpenMandriva)

### FreeBSD
- Uses pkg package manager

### NetBSD
- Uses pkgin package manager

### Windows
- Uses winget (native) or Chocolatey (fallback)

## Command Line Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-v, --version` | Show version information |
| `--dry-run` | Show what would be done without actually doing it |
| `--skip-checksum` | Skip checksum verification (not recommended) |
| `--install-completions` | Install shell completions |
| `--install-manpage` | Install manpage |
| `--config FILE` | Use custom TOML configuration file (default: packages.toml) |
| `--list-groups` | List available package groups |
| `--install-group GROUP` | Install packages from specified group |

## Shell Completions

The script can install completions for:

- **Bash**: `~/.local/share/bash-completion/completions/universal-install`
- **Zsh**: `~/.local/share/zsh/site-functions/_universal-install`
- **Fish**: `~/.config/fish/completions/universal-install.fish`

After installation, restart your shell or run:
```bash
source ~/.bashrc  # for bash
source ~/.zshrc   # for zsh
source ~/.config/fish/config.fish  # for fish
```

## TOML Configuration

The script uses TOML configuration files to define package groups for different platforms. The default configuration file is `packages.toml`.

### Available Package Groups

- **development** - Essential development tools and utilities
- **python** - Python programming language and tools
- **nodejs** - Node.js JavaScript runtime and npm
- **rust** - Rust programming language and Cargo
- **go** - Go programming language
- **java** - Java Development Kit (JDK)
- **containers** - Docker and container management tools
- **cloud** - Cloud platform CLI tools
- **databases** - Database clients and management tools
- **security** - Security and penetration testing tools
- **minimal** - Basic essential tools only

### TOML File Structure

```toml
[metadata]
name = "Universal Installer Packages"
version = "1.0.0"

[groups.development]
name = "Development Tools"
description = "Essential development tools and utilities"
packages = ["git", "vim", "curl", "wget", "jq", "tree", "htop", "tmux"]

[groups.development.platforms]
macos = ["git", "vim", "curl", "wget", "jq", "tree", "htop", "tmux", "coreutils"]
linux.debian = ["git", "vim", "curl", "wget", "jq", "tree", "htop", "tmux", "build-essential"]

[groups.python]
name = "Python"
description = "Python programming language and tools"
packages = ["python3", "pip"]

[groups.python.platforms]
macos = ["python", "pip"]
linux.debian = ["python3", "python3-pip", "python3-venv"]

[groups.nodejs]
name = "Node.js"
description = "Node.js JavaScript runtime and npm"
packages = ["nodejs", "npm"]

[groups.nodejs.platforms]
macos = ["node", "npm"]
linux.debian = ["nodejs", "npm"]

[package_managers]
macos = "brew"
linux.debian = "apt"
linux.redhat = "dnf"

[package_mappings]
macos = {"python3" = "python", "nodejs" = "node"}
linux.debian = {"python3" = "python3", "nodejs" = "nodejs"}
```

### Using Custom Configurations

Create your own TOML file and use it with the `--config` option:

```bash
./install.sh --config my-packages.toml --install-group development
```

## Documentation

### Manpage
Install the manpage with `--install-manpage` and view it with:
```bash
man universal-install
```

### Help
Get help anytime with:
```bash
./install.sh --help
```

## Installation Locations

The script installs files to:

- **Binaries**: `~/.local/bin/universal-install`, `~/.local/bin/universal-uninstall`
- **Completions**: Shell-specific completion directories
- **Manpage**: `~/.local/share/man/man1/universal-install.1`

## Security

The script downloads files from GitHub releases and verifies their integrity
using SHA256 checksums. The script automatically detects available checksum tools
in this order: `shasum`, `sha256sum`, `openssl`. If no checksum tool is available,
the script will warn and continue without verification.

The `--skip-checksum` option should only be used in emergency situations where
checksum verification is failing due to network issues.

## Dependency Handling

If `curl` or `unzip` are not installed, the script will automatically attempt to download and use [`install_pkg.sh`](https://raw.githubusercontent.com/gregnazario/universal-installer/efb41d2d57b7733ad579cbe2979e126b7828f97a/scripts/install_pkg.sh) to install the missing dependency. This ensures the installer can proceed even on minimal systems.

- If neither `curl` nor `wget` is available, the script will attempt to install `curl` using `install_pkg.sh`.
- If neither `unzip` nor `bsdtar` is available, the script will attempt to install `unzip` using `install_pkg.sh`.
- If all automated attempts fail, the script will prompt you to install the dependency manually.

## Troubleshooting

### Checksum Verification Fails
If you're experiencing network issues with checksum verification, you can temporarily skip it:
```bash
./install.sh --skip-checksum
```

### Unsupported Platform
If your platform isn't supported, the script will exit with an error message. Please report unsupported platforms as issues.

### Shell Completions Not Working
1. Ensure you used `--install-completions`
2. Restart your shell or source your shell configuration file
3. Check that the completion files were installed to the correct location

## Development

### Project Structure
```
install-scripts/
├── install.sh                    # Main installation script
├── packages.toml                 # Default TOML configuration
├── completions/                  # Shell completion scripts
│   ├── bash/universal-install
│   ├── zsh/_universal-install
│   └── fish/universal-install.fish
├── man/                          # Manpage
│   └── universal-install.1
└── README.md                     # This file
```

### Adding New Platforms
To add support for a new platform:

1. Add platform detection in `detect_os()` function
2. Add package manager handling in `install_package_manager()` function
3. Test on the target platform
4. Update documentation

## License

Copyright (c) 2024 Universal Installer Team. This is free software.

## Contributing

Report bugs and feature requests to: https://github.com/gregnazario/universal-installer/issues 