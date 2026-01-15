# Project Context

## Purpose
Netshoot is a comprehensive Docker container image packed with network troubleshooting and debugging tools. It is designed to be used as a sidecar container or standalone tool for debugging network issues in Kubernetes and other containerized environments. The goal is to provide a single, portable image with all the necessary tools for quick and effective network diagnostics.

## Tech Stack
- **Base OS**: Ubuntu Linux (latest)
- **Containerization**: Docker
- **Build System**: Dockerfile with multi-stage builds, Makefile
- **Scripting**: Bash, Zsh
- **Included Tools**:
  - Networking: ping, traceroute, tcpdump, nmap, iptables, iproute2, iftop, iperf3, dhcping, ethtool, conntrack, ipvsadm, mtr, ngrep, socat, tcptraceroute, apache2-utils, bind9-utils, bridge-utils, dnsutils, nftables, openssl, speedtest-cli, whois, net-tools, netcat-openbsd, ipset, fping, snmp, scapy, tshark
  - System Utilities: file, jq, rsync, tree, xz-utils, tar, bzip2, gzip, zstd, zip, unzip, procps, ltrace, strace, pv, expect, parallel, man-db, bash, busybox, util-linux, ufw, sudo, swaks
  - Development: git, gcc, g++, Python3, pip, pipx, Go 1.25.5, Node.js (LTS via nvm), maven, openjdk-21-jdk, cmake, ccache, gdb, clang, make, valgrind, bear, build-essential, python3-dev, python3-venv, python3-setuptools, httpie, openssh-client, perl, tmux, vim
  - Modern Unix: bat, fd-find, ripgrep, hyperfine, gping, fzf, glow, curlie, gtop
  - VNC: tightvncserver, gnome-session, metacity, nautilus, gnome-terminal, ubuntu-desktop, tracker, dbus, dbus-x11, gnome-panel, gnome-settings-daemon
  - Container Tools: Docker, ctop, calicoctl
  - Protocol Testing: grpcurl, websocat, witr, fortio, swaks
  - Custom Scripts: `file_compress` (v1.1.0 - multi-format compression with progress tracking), `file_split` (file splitting with SHA-256 checksum verification)

## Project Structure
```
/home/docker/workspace/git/netshoot/
├── build/
│   ├── dotfiles/           # Configuration files for shell, vim, etc.
│   │   └── .config/
│   │       ├── .bashrc
│   │       ├── .p10k.zsh        # Powerlevel10k configuration
│   │       ├── .vimrc
│   │       ├── .xstartup        # VNC startup script
│   │       ├── .zimrc           # Zim framework config
│   │       ├── .zshrc_extra     # Additional zsh config
│   │       ├── config.lua       # Neovim config
│   │       └── init.lua         # Neovim init
│   ├── kubernetes_configs/ # Kubernetes deployment files
│   │   ├── netshoot-calico.yaml    # Calico network debugging
│   │   └── netshoot-sidecar.yaml   # Sidecar deployment example
│   └── scripts/            # Build and installation scripts
│       ├── fetch_binaries.sh    # Fetches external binaries (ctop, calicoctl, etc.)
│       └── install_dev_utils.sh # Installs development utilities (Zim, nvm, Neovim, etc.)
├── openspec/               # OpenSpec specifications
│   ├── AGENTS.md          # AI agent instructions
│   ├── changes/           # Change proposals
│   ├── specs/             # Feature specifications
│   └── project.md         # Project context (this file)
├── Dockerfile             # Multi-stage Docker build file
├── Makefile               # Build automation (build-x86, build-arm64, push)
├── file_compress          # Custom compression utility (v1.1.0)
├── file_split             # Custom file splitting utility
└── .github/               # GitHub workflows and settings
    ├── workflows/
    │   ├── test-pr-buildx.yml    # PR build test workflow
    │   └── release-buildx.yml    # Release build and push workflow
    └── dependabot.yml            # Dependency update configuration
```

## Project Conventions

### Code Style
- Bash scripts follow the Unix philosophy: do one thing well, use pipes, handle errors gracefully
- Scripts include:
  - Shebang lines (#!/usr/bin/env bash or #!/bin/bash)
  - Error handling with set -euo pipefail
  - Color-coded logging for better readability (INFO, ERROR, VERBOSE)
  - Usage information with examples
  - Version tracking (VERSION variable)
  - Dry run mode for testing without making changes
  - Input validation and error handling

### Architecture Patterns
- **Docker Multi-Stage Build**: Separates binary fetching from main image build to reduce size
- **Layer Optimization**: Combines package installation commands to minimize image layers
- **Configuration Management**: Dotfiles and configuration are copied from build/dotfiles directory
- **Utility Scripts**: Custom bash scripts follow a modular design with clear function separation
- **Parallel Build**: Docker buildx supports multi-platform builds (linux/amd64, linux/arm64)
- **Binary Fetching**: External tools fetched via GitHub API with architecture detection

### Testing Strategy
- Scripts include dry run modes for testing without making changes
- `file_split` includes SHA-256 checksum verification for split files
- Error handling and validation checks for inputs
- Progress tracking with pv (pipe viewer) for compression operations
- Manifest file generation for split file metadata

### Git Workflow
- **Makefile Targets**:
  - build-x86: Build for AMD64 architecture
  - build-arm64: Build for ARM64 architecture
  - build-all: Build for both architectures using buildx
  - push: Push image to Docker registry
  - all: Build and push (default target)
- **Image Naming**: nicolaka/netshoot:version (version defined in Makefile as 0.1)
- **Branching**: Current main branch is used for development

### CI/CD Pipeline
- **PR Testing**: test-pr-buildx.yml runs multi-platform builds on pull requests
- **Release Process**: release-buildx.yml builds and pushes images to Docker Hub and GitHub Container Registry on tag pushes (v* pattern)
- **Dependency Management**: dependabot.yml automatically updates Docker and GitHub Actions dependencies daily

### Custom Scripts Details

#### file_compress (v1.1.0)
- **Purpose**: Multi-format compression utility with progress tracking
- **Supported Formats**: zstd (default), gzip, bzip2, xz, none
- **Features**:
  - Progress tracking with `pv` (pipe viewer)
  - Dry run mode for simulation
  - Color-coded logging
  - Compression level control (-100 to 22 for zstd, 1-9 for others)
  - Multi-threading support for zstd (default: CPU cores × 2)
  - Compression ratio calculation
- **Dependencies**: zstd, gzip, bzip2, xz (optional: pv for progress)

#### file_split
- **Purpose**: Unix-style file splitting with checksum verification
- **Actions**: split, verify, cleanup
- **Features**:
  - SHA-256 checksum verification
  - Manifest file generation with metadata
  - Dry run mode
  - Human-readable size parsing (K, M, G suffixes)
  - File reassembly with verification
  - Cleanup functionality
  - Progress tracking with `pv` (pipe viewer) when available
- **Dependencies**: split, cat, sha256sum, wc, stat (optional: pv for progress tracking)

## Domain Context
Netshoot is primarily used for network troubleshooting in containerized environments. Key use cases include:
- Debugging Kubernetes network policies
- Testing connectivity between containers
- Analyzing network traffic with tcpdump and Wireshark
- Troubleshooting DNS issues
- Performance testing with iperf3
- Container network monitoring with ctop
- Calico network policy management with calicoctl
- gRPC and WebSocket testing

## Important Constraints
- **Containerized Environment**: Designed to run as a Docker container
- **Root Access**: Most tools require root privileges
- **Size**: Image includes a large number of tools, resulting in a relatively large size (~1GB)
- **Locale**: English (en_US.UTF-8) is the default locale

## External Dependencies
- GitHub API: Used to fetch latest versions of binary tools (ctop, calicoctl, termshark, etc.)
- Package Repositories: Ubuntu apt-get repositories, npm, pip, go modules
- External Tools:
  - ctop (container monitoring)
  - calicoctl (Calico network policy tool)
  - termshark (terminal-based Wireshark)
  - grpcurl (gRPC testing tool)
  - fortio (load testing tool)
  - witr (WebSocket testing tool)
  - websocat (WebSocket client)
