# Universal Installer fish completion script

complete -c universal-install -c install.sh -s h -l help -d "Show help message"
complete -c universal-install -c install.sh -s v -l version -d "Show version information"
complete -c universal-install -c install.sh -l dry-run -d "Show what would be done without actually doing it"
complete -c universal-install -c install.sh -l skip-checksum -d "Skip checksum verification (not recommended)"
complete -c universal-install -c install.sh -l install-completions -d "Install shell completions"
complete -c universal-install -c install.sh -l install-manpage -d "Install manpage"
complete -c universal-install -c install.sh -l config -d "Use custom TOML configuration file"
complete -c universal-install -c install.sh -l list-groups -d "List available package groups"
complete -c universal-install -c install.sh -l install-group -d "Install packages from specified group"

# Package group completions
complete -c universal-install -c install.sh -l install-group -a "development" -d "Development tools"
complete -c universal-install -c install.sh -l install-group -a "python" -d "Python programming language"
complete -c universal-install -c install.sh -l install-group -a "nodejs" -d "Node.js JavaScript runtime"
complete -c universal-install -c install.sh -l install-group -a "rust" -d "Rust programming language"
complete -c universal-install -c install.sh -l install-group -a "go" -d "Go programming language"
complete -c universal-install -c install.sh -l install-group -a "java" -d "Java Development Kit"
complete -c universal-install -c install.sh -l install-group -a "containers" -d "Container tools"
complete -c universal-install -c install.sh -l install-group -a "cloud" -d "Cloud tools"
complete -c universal-install -c install.sh -l install-group -a "databases" -d "Database tools"
complete -c universal-install -c install.sh -l install-group -a "security" -d "Security tools"
complete -c universal-install -c install.sh -l install-group -a "minimal" -d "Minimal tools" 