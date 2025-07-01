#!/bin/sh

# Cross-platform package manager detection and installation script

# Function to detect the operating system
detect_os() {
    case "$(uname -s)" in
        Darwin*)    echo "macos" ;;
        Linux*)     echo "linux" ;;
        FreeBSD*)   echo "freebsd" ;;
        NetBSD*)    echo "netbsd" ;;
        CYGWIN*|MINGW32*|MSYS*|MINGW*) echo "windows" ;;
        *)          echo "unknown" ;;
    esac
}

# Function to detect Linux distribution
detect_linux_distro() {
    if [ -f /etc/os-release ]; then
        # Source the file safely for POSIX compliance
        ID=""
        # shellcheck disable=SC1091
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to parse TOML file (simple implementation)
parse_toml() {
    toml_file="$1"
    section="$2"
    key="$3"
    
    if [ ! -f "$toml_file" ]; then
        return 1
    fi
    
    # Simple TOML parser for basic key-value pairs
    # This is a simplified parser that works for our use case
    awk -v section="$section" -v key="$key" '
    BEGIN {
        in_section = 0
        found = 0
    }
    
    # Match section header
    /^\[.*\]$/ {
        current_section = substr($0, 2, length($0) - 2)
        if (current_section == section) {
            in_section = 1
        } else {
            in_section = 0
        }
    }
    
    # Match key-value pairs within the section
    in_section && /^[[:space:]]*[^#]/ && /=/ {
        split($0, parts, "=")
        current_key = parts[1]
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", current_key)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", parts[2])
        
        if (current_key == key) {
            # Remove quotes if present
            value = parts[2]
            gsub(/^["'\'']|["'\'']$/, "", value)
            print value
            found = 1
            exit
        }
    }
    
    END {
        if (!found) exit 1
    }
    ' "$toml_file"
}

# Function to get package list for a group and platform
get_package_list() {
    toml_file="$1"
    group="$2"
    platform="$3"
    
    # Try platform-specific packages first
    if packages=$(parse_toml "$toml_file" "groups.$group.platforms.$platform" "packages" 2>/dev/null) && [ -n "$packages" ]; then
        echo "$packages"
        return 0
    fi
    
    # Fall back to generic packages
    if packages=$(parse_toml "$toml_file" "groups.$group" "packages" 2>/dev/null) && [ -n "$packages" ]; then
        echo "$packages"
        return 0
    fi
    
    return 1
}

# Function to get package manager for platform
get_package_manager() {
    toml_file="$1"
    platform="$2"
    
    parse_toml "$toml_file" "package_managers" "$platform" 2>/dev/null
}

# Function to map package names for platform
map_package_name() {
    toml_file="$1"
    platform="$2"
    package="$3"
    
    # Try to get mapped name
    if mapped=$(parse_toml "$toml_file" "package_mappings.$platform" "$package" 2>/dev/null) && [ -n "$mapped" ]; then
        echo "$mapped"
    else
        echo "$package"
    fi
}

# Function to install packages from TOML configuration
install_packages_from_toml() {
    toml_file="$1"
    group="$2"
    
    if [ ! -f "$toml_file" ]; then
        echo "Error: TOML configuration file not found: $toml_file"
        return 1
    fi
    
    # Detect platform
    os=$(detect_os)
    distro=""
    
    case "$os" in
        "linux")
            distro=$(detect_linux_distro)
            platform="linux.$distro"
            ;;
        *)
            platform="$os"
            ;;
    esac
    
    # Get package manager
    pkg_manager=$(get_package_manager "$toml_file" "$platform")
    if [ -z "$pkg_manager" ]; then
        echo "Error: No package manager configured for platform: $platform"
        return 1
    fi
    
    # Get package list
    if ! package_list=$(get_package_list "$toml_file" "$group" "$platform"); then
        echo "Error: No packages found for group '$group' on platform '$platform'"
        return 1
    fi
    
    echo "Installing packages for group '$group' on $platform using $pkg_manager..."
    
    # Parse package list (simple comma-separated or space-separated)
    # Remove brackets and quotes, split by comma or space
    packages=$(echo "$package_list" | sed 's/^\[//;s/\]$//;s/"//g;s/'\''//g' | tr ',' ' ')
    
    for package in $packages; do
        # Skip empty entries
        if [ -z "$package" ]; then
            continue
        fi
        
        # Map package name for platform
        mapped_package=$(map_package_name "$toml_file" "$platform" "$package")
        
        echo "Installing $mapped_package..."
        
        # Install package based on package manager
        case "$pkg_manager" in
            "brew")
                brew install "$mapped_package"
                ;;
            "apt"|"apt-get")
                sudo apt-get update && sudo apt-get install -y "$mapped_package"
                ;;
            "dnf")
                sudo dnf install -y "$mapped_package"
                ;;
            "yum")
                sudo yum install -y "$mapped_package"
                ;;
            "pacman")
                sudo pacman -S --noconfirm "$mapped_package"
                ;;
            "zypper")
                sudo zypper install -y "$mapped_package"
                ;;
            "apk")
                sudo apk add "$mapped_package"
                ;;
            "emerge")
                sudo emerge "$mapped_package"
                ;;
            "xbps-install")
                sudo xbps-install "$mapped_package"
                ;;
            "nix-env")
                nix-env -iA nixpkgs."$mapped_package"
                ;;
            "slackpkg")
                sudo slackpkg install "$mapped_package"
                ;;
            "eopkg")
                sudo eopkg install "$mapped_package"
                ;;
            "swupd")
                sudo swupd bundle-add "$mapped_package"
                ;;
            "urpmi")
                sudo urpmi "$mapped_package"
                ;;
            "pkg")
                sudo pkg install "$mapped_package"
                ;;
            "pkgin")
                sudo pkgin install "$mapped_package"
                ;;
            "winget")
                winget install "$mapped_package"
                ;;
            *)
                echo "Warning: Unsupported package manager '$pkg_manager' for package '$mapped_package'"
                ;;
        esac
    done
    
    echo "Package installation for group '$group' completed."
}

# Function to list available groups
list_available_groups() {
    toml_file="$1"
    
    if [ ! -f "$toml_file" ]; then
        echo "Error: TOML configuration file not found: $toml_file"
        return 1
    fi
    
    echo "Available package groups:"
    echo ""
    
    # Extract group information from TOML
    awk '
    /^\[groups\.[^.]+\]$/ {
        group = substr($0, 9, length($0) - 9)
        in_group = 1
        next
    }
    
    in_group && /^\[/ {
        in_group = 0
    }
    
    in_group && /^[[:space:]]*name[[:space:]]*=/ {
        split($0, parts, "=")
        name = parts[2]
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", name)
        gsub(/^["'\'']|["'\'']$/, "", name)
        group_names[group] = name
    }
    
    in_group && /^[[:space:]]*description[[:space:]]*=/ {
        split($0, parts, "=")
        desc = parts[2]
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", desc)
        gsub(/^["'\'']|["'\'']$/, "", desc)
        group_descs[group] = desc
    }
    
    END {
        for (group in group_names) {
            printf "  %-15s - %s\n", group, group_names[group]
            if (group_descs[group] != "") {
                printf "                %s\n", group_descs[group]
            }
            printf "\n"
        }
    }
    ' "$toml_file"
}

# Function to install package manager based on platform
install_package_manager() {
    os=$(detect_os)
    distro=""
    
    case "$os" in
        "macos")
            if ! command_exists brew; then
                echo "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            else
                echo "Homebrew is already installed."
            fi
            ;;
        "linux")
            distro="$(detect_linux_distro)"
            case "$distro" in
                # Debian-based distributions
                "ubuntu"|"debian"|"linuxmint"|"pop"|"elementary"|"kali"|"parrot"|"mx"|"devuan"|"deepin"|"zorin")
                    if ! command_exists apt; then
                        echo "Error: apt package manager not found on $distro"
                        exit 1
                    else
                        echo "Using native apt package manager on $distro"
                    fi
                    ;;
                # Red Hat-based distributions
                "fedora"|"rhel"|"centos"|"rocky"|"alma"|"oracle"|"amazon"|"scientific")
                    if ! command_exists dnf; then
                        if ! command_exists yum; then
                            echo "Error: Neither dnf nor yum package manager found on $distro"
                            exit 1
                        else
                            echo "Using native yum package manager on $distro"
                        fi
                    else
                        echo "Using native dnf package manager on $distro"
                    fi
                    ;;
                # Arch-based distributions
                "arch"|"manjaro"|"endeavouros"|"garuda"|"arcolinux"|"artix")
                    if ! command_exists pacman; then
                        echo "Error: pacman package manager not found on $distro"
                        exit 1
                    else
                        echo "Using native pacman package manager on $distro"
                    fi
                    ;;
                # SUSE-based distributions
                "opensuse"|"sles"|"suse"|"tumbleweed"|"leap")
                    if ! command_exists zypper; then
                        echo "Error: zypper package manager not found on $distro"
                        exit 1
                    else
                        echo "Using native zypper package manager on $distro"
                    fi
                    ;;
                # Alpine Linux
                "alpine")
                    if ! command_exists apk; then
                        echo "Error: apk package manager not found on $distro"
                        exit 1
                    else
                        echo "Using native apk package manager on $distro"
                    fi
                    ;;
                # Gentoo-based distributions
                "gentoo"|"funtoo"|"calculate")
                    if ! command_exists emerge; then
                        echo "Error: emerge package manager not found on $distro"
                        exit 1
                    else
                        echo "Using native emerge package manager on $distro"
                    fi
                    ;;
                # Void Linux
                "void")
                    if ! command_exists xbps-install; then
                        echo "Error: xbps package manager not found on $distro"
                        exit 1
                    else
                        echo "Using native xbps package manager on $distro"
                    fi
                    ;;
                # NixOS
                "nixos")
                    if ! command_exists nix-env; then
                        echo "Error: nix package manager not found on $distro"
                        exit 1
                    else
                        echo "Using native nix package manager on $distro"
                    fi
                    ;;
                # Slackware-based distributions
                "slackware"|"slax"|"salix")
                    if ! command_exists slackpkg; then
                        echo "Error: slackpkg package manager not found on $distro"
                        exit 1
                    else
                        echo "Using native slackpkg package manager on $distro"
                    fi
                    ;;
                # Solus
                "solus")
                    if ! command_exists eopkg; then
                        echo "Error: eopkg package manager not found on $distro"
                        exit 1
                    else
                        echo "Using native eopkg package manager on $distro"
                    fi
                    ;;
                # Clear Linux
                "clear-linux-os")
                    if ! command_exists swupd; then
                        echo "Error: swupd package manager not found on $distro"
                        exit 1
                    else
                        echo "Using native swupd package manager on $distro"
                    fi
                    ;;
                # PCLinuxOS
                "pclinuxos")
                    if ! command_exists apt-get; then
                        echo "Error: apt-get package manager not found on $distro"
                        exit 1
                    else
                        echo "Using native apt-get package manager on $distro"
                    fi
                    ;;
                # Mageia
                "mageia")
                    if ! command_exists urpmi; then
                        echo "Error: urpmi package manager not found on $distro"
                        exit 1
                    else
                        echo "Using native urpmi package manager on $distro"
                    fi
                    ;;
                # OpenMandriva
                "openmandriva")
                    if ! command_exists dnf; then
                        echo "Error: dnf package manager not found on $distro"
                        exit 1
                    else
                        echo "Using native dnf package manager on $distro"
                    fi
                    ;;
                *)
                    echo "Warning: Unknown Linux distribution '$distro'. Attempting to continue..."
                    ;;
            esac
            ;;
        "freebsd")
            if ! command_exists pkg; then
                echo "Error: pkg package manager not found on FreeBSD"
                exit 1
            else
                echo "Using native pkg package manager on FreeBSD"
            fi
            ;;
        "netbsd")
            if ! command_exists pkgin; then
                echo "Error: pkgin package manager not found on NetBSD"
                exit 1
            else
                echo "Using native pkgin package manager on NetBSD"
            fi
            ;;
        "windows")
            if ! command_exists winget; then
                if ! command_exists choco; then
                    echo "Installing Chocolatey..."
                    powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
                else
                    echo "Chocolatey is already installed."
                fi
            else
                echo "Using native winget package manager on Windows"
            fi
            ;;
        *)
            echo "Error: Unsupported operating system: $os"
            exit 1
            ;;
    esac
}

# Function to check if a checksum tool is available
get_checksum_tool() {
    if command_exists shasum; then
        echo "shasum"
    elif command_exists sha256sum; then
        echo "sha256sum"
    elif command_exists openssl; then
        echo "openssl"
    else
        echo ""
    fi
}

# Function to verify checksum using available tool
verify_checksum() {
    file="$1"
    expected_hash="$2"
    tool="$3"
    
    case "$tool" in
        "shasum")
            echo "$expected_hash  $file" | shasum -a 256 -c
            ;;
        "sha256sum")
            echo "$expected_hash  $file" | sha256sum -c
            ;;
        "openssl")
            actual_hash=$(openssl dgst -sha256 "$file" | awk '{print $2}')
            if [ "$actual_hash" = "$expected_hash" ]; then
                return 0
            else
                return 1
            fi
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to install missing dependencies using install_pkg.sh
install_missing_dependency() {
    dependency="$1"
    
    # Check if dependency is already available
    if command_exists "$dependency"; then
        return 0
    fi
    
    echo "Dependency '$dependency' not found. Attempting to install using install_pkg.sh..."
    
    # Check if install_pkg.sh exists in current directory
    if [ -f "./install_pkg.sh" ]; then
        script_path="./install_pkg.sh"
    elif [ -f "$(dirname "$0")/install_pkg.sh" ]; then
        script_path="$(dirname "$0")/install_pkg.sh"
    else
        # Download install_pkg.sh if not available
        echo "Downloading install_pkg.sh..."
        if command_exists curl; then
            curl -fsSL "https://raw.githubusercontent.com/gregnazario/universal-installer/efb41d2d57b7733ad579cbe2979e126b7828f97a/scripts/install_pkg.sh" -o install_pkg.sh
            script_path="./install_pkg.sh"
        elif command_exists wget; then
            wget -O install_pkg.sh "https://raw.githubusercontent.com/gregnazario/universal-installer/efb41d2d57b7733ad579cbe2979e126b7828f97a/scripts/install_pkg.sh"
            script_path="./install_pkg.sh"
        else
            echo "Error: Cannot download install_pkg.sh - neither curl nor wget available."
            echo "Please install curl or wget manually and rerun the script."
            exit 1
        fi
        chmod +x "$script_path"
    fi
    
    # Install the dependency
    if sh "$script_path" "$dependency"; then
        echo "Successfully installed $dependency"
        return 0
    else
        echo "Error: Failed to install $dependency using install_pkg.sh"
        return 1
    fi
}

# Function to download a file using curl or wget as fallback
download_file() {
    url="$1"
    output="$2"
    if command_exists curl; then
        curl -L -o "$output" "$url"
    elif command_exists wget; then
        wget -O "$output" "$url"
    else
        echo "Error: Neither 'curl' nor 'wget' is available to download files."
        echo "Attempting to install curl..."
        if install_missing_dependency curl; then
            curl -L -o "$output" "$url"
        else
            echo "Failed to install curl. Please install 'curl' or 'wget' manually and rerun the script."
            exit 1
        fi
    fi
}

# Function to download and verify Universal Installer
download_universal_installer() {
    echo "Downloading Universal Installer..."
    download_file "https://github.com/gregnazario/universal-installer/releases/download/v0.1.0/universal-installer.zip" universal-installer.zip

    # Check if we should skip checksum verification
    if [ "$SKIP_CHECKSUM" = "true" ]; then
        echo "Skipping checksum verification as requested."
        return 0
    fi

    # Get checksum tool
    checksum_tool=$(get_checksum_tool)
    if [ -z "$checksum_tool" ]; then
        echo "Warning: No checksum verification tool found (shasum, sha256sum, or openssl)"
        echo "Skipping checksum verification. Use --skip-checksum to suppress this warning."
        return 0
    fi

    echo "Using $checksum_tool for checksum verification..."
    
    # Download the expected SHA256 checksum
    download_file "https://github.com/gregnazario/universal-installer/releases/download/v0.1.0/universal-installer.zip.sha256" universal-installer.zip.sha256
    
    # Read the expected hash
    expected_hash=$(awk '{print $1}' universal-installer.zip.sha256)
    
    if [ -z "$expected_hash" ]; then
        echo "Error: Could not read expected checksum from file"
        exit 1
    fi
    
    # Verify the checksum
    if verify_checksum "universal-installer.zip" "$expected_hash" "$checksum_tool"; then
        echo "Checksum verification passed."
    else
        echo "Checksum verification failed. Exiting."
        exit 1
    fi
}

# Function to install Universal Installer
install_universal_installer() {
    echo "Unzipping Universal Installer..."
    if command_exists unzip; then
        unzip -o universal-installer.zip -d universal-installer
    elif command_exists bsdtar; then
        bsdtar -xf universal-installer.zip -C universal-installer
    else
        echo "Error: Neither 'unzip' nor 'bsdtar' is available to extract the installer."
        echo "Attempting to install unzip..."
        if install_missing_dependency unzip; then
            unzip -o universal-installer.zip -d universal-installer
        else
            echo "Failed to install unzip. Please install 'unzip' or 'bsdtar' manually and rerun the script."
            exit 1
        fi
    fi

    # Move the Universal Installer to ~/.local/bin
    # Ensure the directory exists
    mkdir -p ~/.local/bin
    mv universal-installer/universal-installer/scripts/install_pkg.sh ~/.local/bin/universal-install
    mv universal-installer/universal-installer/scripts/uninstall_pkg.sh ~/.local/bin/universal-uninstall

    # Make the scripts executable
    chmod +x ~/.local/bin/universal-install
    chmod +x ~/.local/bin/universal-uninstall

    # Clean up
    rm -rf universal-installer.zip universal-installer universal-installer.zip.sha256
}

# Function to show help
show_help() {
    cat << 'EOF'
Universal Installer Setup Script

USAGE:
    install.sh [OPTIONS] [PACKAGE_GROUPS]

OPTIONS:
    -h, --help          Show this help message
    -v, --version       Show version information
    --dry-run          Show what would be done without actually doing it
    --skip-checksum    Skip checksum verification (not recommended, auto-detects shasum/sha256sum/openssl)
    --install-completions  Install shell completions
    --install-manpage  Install manpage
    --install-package-manpages  Install man pages for packages in groups
    --config FILE      Use custom TOML configuration file (default: packages.toml)
    --list-groups      List available package groups
    --install-group GROUP  Install packages from specified group

DESCRIPTION:
    This script sets up the Universal Installer on your system by:
    1. Detecting your platform and package manager
    2. Downloading and verifying the Universal Installer
    3. Installing it to ~/.local/bin
    4. Optionally installing shell completions and manpage
    5. Optionally installing packages from TOML configuration

EXAMPLES:
    ./install.sh                                    # Normal installation
    ./install.sh --dry-run                          # See what would be installed
    ./install.sh --install-completions              # Install with completions
    ./install.sh --install-manpage                  # Install manpage
    ./install.sh --install-package-manpages         # Install package man pages
    ./install.sh --list-groups                      # List available package groups
    ./install.sh --install-group development        # Install development tools
    ./install.sh --install-group python,nodejs      # Install multiple language groups
    ./install.sh --config custom.toml --install-group minimal  # Use custom config
    ./install.sh --help                             # Show this help

PACKAGE GROUPS:
    development  - Essential development tools and utilities
    python       - Python programming language and tools
    nodejs       - Node.js JavaScript runtime and npm
    rust         - Rust programming language and Cargo
    go           - Go programming language
    java         - Java Development Kit (JDK)
    containers   - Docker and container management tools
    cloud        - Cloud platform CLI tools
    databases    - Database clients and management tools
    security     - Security and penetration testing tools
    minimal      - Basic essential tools only

SUPPORTED PLATFORMS:
    - macOS (Homebrew)
    - Linux (apt, dnf, pacman, zypper, apk, emerge, xbps, nix, slackpkg, eopkg, swupd, urpmi)
    - FreeBSD (pkg)
    - NetBSD (pkgin)
    - Windows (winget, Chocolatey)

AUTHOR:
    Universal Installer Team

For more information, see: https://github.com/gregnazario/universal-installer
EOF
}

# Function to show version
show_version() {
    echo "Universal Installer Setup Script v1.0.0"
    echo "Copyright (c) 2024 Universal Installer Team"
}

# Function to install shell completions
install_completions() {
    script_dir="$(cd "$(dirname "$0")" && pwd)"
    completion_dir=""
    shell_rc=""
    completion_file=""
    
    case "$SHELL" in
        */bash)
            completion_dir="$HOME/.local/share/bash-completion/completions"
            shell_rc="$HOME/.bashrc"
            completion_file="$script_dir/completions/bash/universal-install"
            ;;
        */zsh)
            completion_dir="$HOME/.local/share/zsh/site-functions"
            shell_rc="$HOME/.zshrc"
            completion_file="$script_dir/completions/zsh/_universal-install"
            ;;
        */fish)
            completion_dir="$HOME/.config/fish/completions"
            shell_rc="$HOME/.config/fish/config.fish"
            completion_file="$script_dir/completions/fish/universal-install.fish"
            ;;
        *)
            echo "Warning: Unsupported shell '$SHELL'. Completions not installed."
            return 1
            ;;
    esac
    
    mkdir -p "$completion_dir"
    
    # Copy completion file if it exists, otherwise create a basic one
    if [ -f "$completion_file" ]; then
        cp "$completion_file" "$completion_dir/"
        echo "Installed completion script from $completion_file"
    else
        # Fallback: create basic completion
        case "$SHELL" in
            */bash)
                cat > "$completion_dir/universal-install" << 'EOF'
# Universal Installer completion script

_universal_install_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    opts="--help --version --dry-run --skip-checksum --install-completions --install-manpage"
    
    if [[ ${cur} == * ]] ; then
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi
}

complete -F _universal_install_completion install.sh
complete -F _universal_install_completion universal-install
EOF
                ;;
            */zsh)
                cat > "$completion_dir/_universal-install" << 'EOF'
#compdef universal-install install.sh

_universal_install() {
    local curcontext="$curcontext" state line
    typeset -A opt_args

    _arguments -C \
        '1: :->cmds' \
        '*:: :->args'

    case "$state" in
        cmds)
            _values 'universal-install options' \
                '--help[Show help message]' \
                '--version[Show version information]' \
                '--dry-run[Show what would be done without actually doing it]' \
                '--skip-checksum[Skip checksum verification]' \
                '--install-completions[Install shell completions]' \
                '--install-manpage[Install manpage]'
            ;;
        args)
            case $line[1] in
                --help|--version)
                    # No additional arguments needed
                    ;;
                --dry-run|--skip-checksum|--install-completions|--install-manpage)
                    # These options don't take arguments
                    ;;
            esac
            ;;
    esac
}

_universal_install "$@"
EOF
                ;;
            */fish)
                cat > "$completion_dir/universal-install.fish" << 'EOF'
# Universal Installer fish completion script

complete -c universal-install -c install.sh -s h -l help -d "Show help message"
complete -c universal-install -c install.sh -s v -l version -d "Show version information"
complete -c universal-install -c install.sh -l dry-run -d "Show what would be done without actually doing it"
complete -c universal-install -c install.sh -l skip-checksum -d "Skip checksum verification (not recommended)"
complete -c universal-install -c install.sh -l install-completions -d "Install shell completions"
complete -c universal-install -c install.sh -l install-manpage -d "Install manpage"
EOF
                ;;
        esac
        echo "Created basic completion script for $SHELL"
    fi
    
    # Add to shell rc if not already present
    if ! grep -q "universal-install" "$shell_rc" 2>/dev/null; then
        {
            echo ""
            echo "# Universal Installer completions"
            echo "if [ -d \"$completion_dir\" ]; then"
            echo "    export FPATH=\"$completion_dir:\$FPATH\""
            echo "fi"
        } >> "$shell_rc"
    fi
    
    echo "Shell completions installed to $completion_dir"
    echo "Please restart your shell or run: source $shell_rc"
}

# Function to install man pages for packages
install_package_manpages() {
    toml_file="$1"
    group="$2"
    
    if [ ! -f "$toml_file" ]; then
        echo "Error: TOML configuration file not found: $toml_file"
        return 1
    fi
    
    # Detect platform
    os=$(detect_os)
    distro=""
    
    case "$os" in
        "linux")
            distro=$(detect_linux_distro)
            platform="linux.$distro"
            ;;
        *)
            platform="$os"
            ;;
    esac
    
    # Get package list
    if ! package_list=$(get_package_list "$toml_file" "$group" "$platform"); then
        echo "Error: No packages found for group '$group' on platform '$platform'"
        return 1
    fi
    
    echo "Installing man pages for packages in group '$group' on $platform..."
    
    # Parse package list
    packages=$(echo "$package_list" | sed 's/^\[//;s/\]$//;s/"//g;s/'\''//g' | tr ',' ' ')
    
    for package in $packages; do
        # Skip empty entries
        if [ -z "$package" ]; then
            continue
        fi
        
        # Map package name for platform
        mapped_package=$(map_package_name "$toml_file" "$platform" "$package")
        
        echo "Installing man pages for $mapped_package..."
        
        # Install man pages based on platform
        case "$os" in
            "macos")
                # macOS: man pages are usually included with packages
                echo "Man pages for $mapped_package should be available with the package"
                ;;
            "linux")
                case "$distro" in
                    "ubuntu"|"debian"|"linuxmint"|"pop"|"elementary"|"kali"|"parrot"|"mx"|"devuan"|"deepin"|"zorin"|"pclinuxos")
                        # Debian-based: install -doc packages
                        doc_package="${mapped_package}-doc"
                        if command_exists apt; then
                            sudo apt install -y "$doc_package" 2>/dev/null || echo "No -doc package available for $mapped_package"
                        elif command_exists apt-get; then
                            sudo apt-get install -y "$doc_package" 2>/dev/null || echo "No -doc package available for $mapped_package"
                        fi
                        ;;
                    "fedora"|"rhel"|"centos"|"rocky"|"almalinux"|"oracle"|"amazon"|"scientific"|"openmandriva")
                        # Red Hat-based: install -doc packages
                        doc_package="${mapped_package}-doc"
                        if command_exists dnf; then
                            sudo dnf install -y "$doc_package" 2>/dev/null || echo "No -doc package available for $mapped_package"
                        elif command_exists yum; then
                            sudo yum install -y "$doc_package" 2>/dev/null || echo "No -doc package available for $mapped_package"
                        fi
                        ;;
                    "arch"|"manjaro"|"endeavouros"|"garuda"|"arcolinux"|"artix")
                        # Arch-based: man pages are usually included
                        echo "Man pages for $mapped_package should be available with the package"
                        ;;
                    "opensuse"|"sle"|"tumbleweed"|"leap")
                        # SUSE-based: install -doc packages
                        doc_package="${mapped_package}-doc"
                        sudo zypper install -y "$doc_package" 2>/dev/null || echo "No -doc package available for $mapped_package"
                        ;;
                    "alpine")
                        # Alpine: man pages are usually included
                        echo "Man pages for $mapped_package should be available with the package"
                        ;;
                    "gentoo"|"funtoo"|"calculate")
                        # Gentoo: man pages are usually included
                        echo "Man pages for $mapped_package should be available with the package"
                        ;;
                    "void")
                        # Void: man pages are usually included
                        echo "Man pages for $mapped_package should be available with the package"
                        ;;
                    "nixos")
                        # NixOS: man pages are usually included
                        echo "Man pages for $mapped_package should be available with the package"
                        ;;
                    "slackware"|"slax"|"salix")
                        # Slackware: man pages are usually included
                        echo "Man pages for $mapped_package should be available with the package"
                        ;;
                    "solus")
                        # Solus: man pages are usually included
                        echo "Man pages for $mapped_package should be available with the package"
                        ;;
                    "clearlinux")
                        # Clear Linux: man pages are usually included
                        echo "Man pages for $mapped_package should be available with the package"
                        ;;
                    "mageia")
                        # Mageia: install -doc packages
                        doc_package="${mapped_package}-doc"
                        sudo urpmi "$doc_package" 2>/dev/null || echo "No -doc package available for $mapped_package"
                        ;;
                    *)
                        echo "Unknown Linux distribution: $distro"
                        ;;
                esac
                ;;
            "freebsd")
                # FreeBSD: man pages are usually included
                echo "Man pages for $mapped_package should be available with the package"
                ;;
            "netbsd")
                # NetBSD: man pages are usually included
                echo "Man pages for $mapped_package should be available with the package"
                ;;
            "windows")
                # Windows: man pages not applicable
                echo "Man pages not applicable on Windows for $mapped_package"
                ;;
            *)
                echo "Unknown operating system: $os"
                ;;
        esac
    done
}

# Function to install manpage
install_manpage() {
    script_dir="$(cd "$(dirname "$0")" && pwd)"
    man_dir="$HOME/.local/share/man/man1"
    manpage_file="$script_dir/man/universal-install.1"
    
    mkdir -p "$man_dir"
    
    # Copy manpage file if it exists, otherwise create a basic one
    if [ -f "$manpage_file" ]; then
        cp "$manpage_file" "$man_dir/"
        echo "Installed manpage from $manpage_file"
    else
        # Fallback: create basic manpage
        cat > "$man_dir/universal-install.1" << 'EOF'
.TH UNIVERSAL-INSTALL 1 "2024" "Universal Installer" "User Commands"

.SH NAME
universal-install \- Cross-platform package installer setup script

.SH SYNOPSIS
.B install.sh
[\fIOPTIONS\fR]

.SH DESCRIPTION
.B universal-install
is a cross-platform script that sets up the Universal Installer on your system.
It automatically detects your platform and package manager, then downloads and
installs the Universal Installer tools.

.SH OPTIONS
.TP
.BR \-h ", " \-\-help
Show help message and exit.

.TP
.BR \-v ", " \-\-version
Show version information and exit.

.TP
.B \-\-dry-run
Show what would be done without actually performing the installation.

.TP
.B \-\-skip-checksum
Skip checksum verification of downloaded files (not recommended).

.TP
.B \-\-install-completions
Install shell completion scripts for the installer.

.TP
.B \-\-install-manpage
Install manpage for the installer.

.SH SUPPORTED PLATFORMS
.TP
.B macOS
Uses Homebrew package manager
.TP
.B Linux
Supports multiple distributions with native package managers
.TP
.B FreeBSD
Uses pkg package manager
.TP
.B NetBSD
Uses pkgin package manager
.TP
.B Windows
Uses winget or Chocolatey

.SH EXAMPLES
.TP
Normal installation:
.B install.sh

.TP
Dry run to see what would be installed:
.B install.sh --dry-run

.TP
Install with completions and manpage:
.B install.sh --install-completions --install-manpage

.SH AUTHOR
Universal Installer Team

.SH COPYRIGHT
Copyright (c) 2024 Universal Installer Team. This is free software.
EOF
        echo "Created basic manpage"
    fi
    
    echo "Manpage installed to $man_dir/universal-install.1"
    echo "You can now view it with: man universal-install"
}

# Function to parse command line arguments
parse_args() {
    install_completions=false
    install_manpage=false
    install_package_manpages=false
    dry_run=false
    skip_checksum=false
    config_file="packages.toml"
    list_groups=false
    install_groups=""
    
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --skip-checksum)
                skip_checksum=true
                shift
                ;;
            --install-completions)
                install_completions=true
                shift
                ;;
            --install-manpage)
                install_manpage=true
                shift
                ;;
            --install-package-manpages)
                install_package_manpages=true
                shift
                ;;
            --config)
                if [ -z "$2" ]; then
                    echo "Error: --config requires a file argument"
                    exit 1
                fi
                config_file="$2"
                shift 2
                ;;
            --list-groups)
                list_groups=true
                shift
                ;;
            --install-group)
                if [ -z "$2" ]; then
                    echo "Error: --install-group requires a group argument"
                    exit 1
                fi
                install_groups="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Export variables for use in main function
    export DRY_RUN="$dry_run"
    export SKIP_CHECKSUM="$skip_checksum"
    export INSTALL_COMPLETIONS="$install_completions"
    export INSTALL_MANPAGE="$install_manpage"
    export INSTALL_PACKAGE_MANPAGES="$install_package_manpages"
    export CONFIG_FILE="$config_file"
    export LIST_GROUPS="$list_groups"
    export INSTALL_GROUPS="$install_groups"
}

# Main execution
main() {
    parse_args "$@"
    
    # Handle list groups option
    if [ "$LIST_GROUPS" = "true" ]; then
        script_dir="$(cd "$(dirname "$0")" && pwd)"
        config_path="$script_dir/$CONFIG_FILE"
        list_available_groups "$config_path"
        exit 0
    fi
    
    if [ "$DRY_RUN" = "true" ]; then
        echo "DRY RUN MODE - No changes will be made"
        echo "Would detect platform and package managers..."
        echo "Would download Universal Installer..."
        echo "Would install to ~/.local/bin"
        if [ "$INSTALL_COMPLETIONS" = "true" ]; then
            echo "Would install shell completions"
        fi
        if [ "$INSTALL_MANPAGE" = "true" ]; then
            echo "Would install manpage"
        fi
        if [ "$INSTALL_PACKAGE_MANPAGES" = "true" ]; then
            echo "Would install package man pages"
        fi
        if [ -n "$INSTALL_GROUPS" ]; then
            echo "Would install packages from groups: $INSTALL_GROUPS"
        fi
        exit 0
    fi
    
    echo "Detecting platform and package managers..."
    install_package_manager
    
    download_universal_installer
    install_universal_installer
    
    if [ "$INSTALL_COMPLETIONS" = "true" ]; then
        echo "Installing shell completions..."
        install_completions
    fi
    
    if [ "$INSTALL_MANPAGE" = "true" ]; then
        echo "Installing manpage..."
        install_manpage
    fi
    
    if [ "$INSTALL_PACKAGE_MANPAGES" = "true" ]; then
        echo "Installing package man pages..."
        script_dir="$(cd "$(dirname "$0")" && pwd)"
        config_path="$script_dir/$CONFIG_FILE"
        
        # Split groups by comma and install man pages for each
        OLD_IFS="$IFS"
        IFS=','
        for group in $INSTALL_GROUPS; do
            IFS="$OLD_IFS"
            group=$(echo "$group" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [ -n "$group" ]; then
                echo ""
                echo "Installing man pages for group: $group"
                install_package_manpages "$config_path" "$group"
            fi
        done
        IFS="$OLD_IFS"
    fi
    
    # Handle package group installation
    if [ -n "$INSTALL_GROUPS" ]; then
        script_dir="$(cd "$(dirname "$0")" && pwd)"
        config_path="$script_dir/$CONFIG_FILE"
        
        echo ""
        echo "Installing packages from TOML configuration..."
        
        # Split groups by comma and install each
        OLD_IFS="$IFS"
        IFS=','
        for group in $INSTALL_GROUPS; do
            IFS="$OLD_IFS"
            group=$(echo "$group" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [ -n "$group" ]; then
                echo ""
                echo "Installing group: $group"
                install_packages_from_toml "$config_path" "$group"
            fi
        done
        IFS="$OLD_IFS"
    fi
    
    echo ""
    echo "Installation complete!"
    echo "Universal installer commands are now available at:"
    echo "  ~/.local/bin/universal-install"
    echo "  ~/.local/bin/universal-uninstall"
    
    if [ "$INSTALL_COMPLETIONS" = "true" ]; then
        echo ""
        echo "Shell completions installed. Please restart your shell or run:"
        echo "  source ~/.bashrc  # for bash"
        echo "  source ~/.zshrc   # for zsh"
        echo "  source ~/.config/fish/config.fish  # for fish"
    fi
    
    if [ "$INSTALL_MANPAGE" = "true" ]; then
        echo ""
        echo "Manpage installed. View it with: man universal-install"
    fi
    
    if [ "$INSTALL_PACKAGE_MANPAGES" = "true" ]; then
        echo ""
        echo "Package man pages installed where available."
    fi

    # Ensure ~/.local/bin is in PATH
    case ":$PATH:" in
        *":$HOME/.local/bin:"*)
            # Already in PATH
            ;;
        *)
            echo ""
            echo "$HOME/.local/bin is not in your PATH. Adding it to your shell profile..."
            shell_profile=""
            if [ -n "$ZSH_VERSION" ]; then
                shell_profile="$HOME/.zshrc"
            elif [ -n "$BASH_VERSION" ]; then
                shell_profile="$HOME/.bashrc"
            elif [ -f "$HOME/.profile" ]; then
                shell_profile="$HOME/.profile"
            else
                shell_profile="$HOME/.profile"
            fi
            echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$shell_profile"
            echo "Added 'export PATH=\"\$HOME/.local/bin:\$PATH\"' to $shell_profile"
            echo "Please restart your shell or run: source $shell_profile"
            ;;
    esac
}

# Run main function
main "$@"