# netshoot

A comprehensive Docker container image packed with network troubleshooting, debugging, and development tools. Designed as a sidecar container or standalone tool for debugging network issues in Kubernetes and other containerized environments.

Based on [nicolaka/netshoot](https://github.com/nicolaka/netshoot), extended with custom utilities, full dev toolchains, VNC/GUI support, and WSL2 setup scripts.

## Features

- **100+ networking tools**: tcpdump, nmap, iperf3, wireshark/tshark, calicoctl, grpcurl, and more
- **Full dev environment**: C/C++, Java, Python, Go, Node.js, Rust — with editors (Vim, Neovim/LazyVim)
- **VNC/GUI access**: tightvncserver + GNOME desktop for graphical tools
- **Custom utilities**: docker_delta, file_compress, file_delta, file_split
- **Multi-arch**: linux/amd64 and linux/arm64 via Docker buildx
- **WSL2 setup**: scripts for air-gapped environment export

## Quick Start

```bash
# Pull and run
docker run -it --rm nicolaka/netshoot:latest zsh

# Run alongside another container (shared network namespace)
docker run -it --rm --network container:myapp nicolaka/netshoot:latest zsh
```

### Kubernetes Sidecar

```bash
kubectl apply -f build/kubernetes_configs/netshoot-sidecar.yaml
kubectl exec -it <pod-name> -c netshoot -- zsh
```

### Kubernetes Calico Debugging

```bash
kubectl apply -f build/kubernetes_configs/netshoot-calico.yaml
kubectl exec -n kube-system -it <pod-name> -- zsh
```

## Build

```bash
# Single architecture
make build-x86        # linux/amd64
make build-arm64      # linux/arm64

# Multi-platform (both)
make build-all

# Build and push
make all
```

Image name: `nicolaka/netshoot:0.1` (configured in [Makefile](Makefile)).

## Architecture

The image uses a two-stage Docker build:

### Stage 1: Binary Fetcher

Downloads external tools from GitHub releases with automatic architecture detection:

| Tool | Purpose |
|------|---------|
| [ctop](https://github.com/bcicen/ctop) | Container monitoring |
| [calicoctl](https://github.com/projectcalico/calico) | Calico network policy management |
| [termshark](https://github.com/gcla/termshark) | Terminal-based Wireshark UI |
| [grpcurl](https://github.com/fullstorydev/grpcurl) | gRPC testing (like curl for gRPC) |
| [fortio](https://github.com/fortio/fortio) | Load testing and latency measurement |
| [witr](https://github.com/nadoo/witr) | WebSocket testing |
| [websocat](https://github.com/vi/websocat) | WebSocket client |

### Stage 2: Main Image

Installs all packages in a single `RUN` layer to minimize image size, then:

1. Copies fetched binaries to `/usr/local/bin/`
2. Copies dotfiles (shell configs, editor configs, VNC settings) from `build/dotfiles/`
3. Runs `install_dev_utils.sh` which installs:
   - **Zim** (Zsh framework) + **Powerlevel10k** prompt
   - **nvm** (Node.js LTS)
   - **Neovim** with LazyVim distribution
   - **Docker** CLI
   - **fzf** (fuzzy finder)
   - **Go 1.25.5**
   - **Claude Code** and AI assistant tooling
   - **Chrome** browser
   - Modern Unix tools (bat, fd, ripgrep, hyperfine, gping, glow, curlie)

### Layer Optimization

All `apt-get install` commands are combined into a single `RUN` directive to reduce the number of image layers. The image uses `linuxmirrors.cn` for mirror optimization.

## Included Tools

### Networking
`ping`, `traceroute`, `tcpdump`, `nmap`, `iptables`, `iproute2`, `iftop`, `iperf3`, `dhcping`, `ethtool`, `conntrack`, `ipvsadm`, `mtr`, `ngrep`, `socat`, `tcptraceroute`, `dnsutils`, `nftables`, `openssl`, `speedtest-cli`, `netcat`, `ipset`, `fping`, `snmp`, `scapy`, `tshark`, `mitmproxy`, `apache2-utils`, `bind9-utils`, `bridge-utils`

### System Utilities
`bash`, `zsh`, `busybox`, `jq`, `rsync`, `tree`, `pv`, `parallel`, `bsdiff`, `xdelta3`, `skopeo`, `ffmpeg`, `qemu`, `strace`, `ltrace`, `gdb`, `valgrind`

### Development
`git`, `gcc`/`g++`, `clang`, `cmake`, `Python3` + `pip`/`pipx`, `Go 1.25.5`, `Node.js` (LTS via nvm), `Java 21` + `Maven`, `Rust` (via rustup), `make`, `ccache`, `bear`

### Modern Unix
`bat`, `fd`, `ripgrep`, `hyperfine`, `gping`, `fzf`, `glow`, `curlie`

### Container Tools
`Docker`, `ctop`, `calicoctl`, `podman`

### Protocol Testing
`grpcurl`, `websocat`, `witr`, `fortio`, `swaks`

### VNC/GUI
`tightvncserver`, `GNOME` desktop, `Chrome`, `Nautilus`, `GNOME Terminal`

## Custom Utility Scripts

Four standalone bash executables at the repository root, designed following the Unix philosophy:

### docker_delta (v1.0.0)

Docker image delta transfer utility — efficiently transfers Docker images by delta encoding layers.

```bash
# Create a delta package from an image
docker_delta create myimage:v1 delta.tar.gz

# Create delta between two image versions
docker_delta create myimage:v1 myimage:v2 update.delta.tar.gz

# Apply a delta package
docker_delta apply update.delta.tar.gz

# List layers in a delta package
docker_delta list delta.tar.gz

# Show package info
docker_delta info delta.tar.gz
```

Supports three delta methods: `xdelta3`, `bsdiff`, and `layer-only`. Integrates Skopeo for local file operations.

### file_compress (v1.2.0)

Multi-format compression with progress tracking and parallel chunk compression.

```bash
# Compress with zstd (default)
file_compress archive.tar

# Use gzip at level 9
file_compress -m gzip -l 9 archive.tar

# Parallel chunk compression
file_compress -t 4 largefile.bin
```

Supports: zstd (default), gzip, bzip2, xz, none. Includes SHA-256 verification and compression ratio calculation.

### file_delta (v1.0.0)

File and directory delta creation and application.

```bash
# Create delta between two files
file_delta create old.tar new.tar patch.delta

# Apply delta
file_delta apply old.tar patch.delta restored.tar

# Directory delta
file_delta create -s dir1/ dir2/ patch.delta
```

Supports xdelta3, bsdiff, and rsync methods.

### file_split

Unix-style file splitting with manifest generation and SHA-256 checksum verification.

```bash
# Split into 100M chunks
file_split split largefile.tar 100M

# Verify integrity
file_split verify largefile.tar.manifest

# Clean up chunks
file_split cleanup largefile.tar.manifest
```

## WSL2 Setup Scripts

Scripts for setting up WSL2 development environments, located in `build/scripts/`:

| Script | Phases | Description |
|--------|--------|-------------|
| `setup_wsl.sh` | 19 | Full setup for air-gapped export — pre-installs everything including all apt packages |
| `setup_wsl_lite.sh` | 18 | Lite setup — defers apt package installation to post-import for smaller export size |
| `setup_dev.sh` | 8 | Minimal dev environment setup with fish shell |

All scripts support **checkpoint/resume** — completed phases are tracked and skipped on re-run, making them safe to interrupt and restart.

### Typical Air-Gapped Workflow

```bash
# 1. Run full setup to create a ready-to-export WSL2 distro
sudo bash build/scripts/setup_wsl.sh

# 2. Export the WSL2 instance
wsl --export my-distro distro.tar

# 3. Transfer to air-gapped machine and import
wsl --import my-distro C:\WSL\my-distro distro.tar
```

## CI/CD

| Workflow | Trigger | Action |
|----------|---------|--------|
| `test-pr-buildx.yml` | PR to `master` | Multi-platform build test (no push) |
| `release-buildx.yml` | Tag push `v*` | Build + push to Docker Hub and GHCR |

Secrets required: `DOCKER_USER`, `DOCKER_PASSWORD`, `GHCR_USER`, `GHCR_TOKEN`.

Dependabot checks Docker and GitHub Actions dependencies daily.

## Project Structure

```
├── Dockerfile                   # Multi-stage Docker build
├── Makefile                     # Build automation
├── docker_delta                 # Docker image delta utility (v1.0.0)
├── file_compress                # Multi-format compression utility (v1.2.0)
├── file_delta                   # File delta utility (v1.0.0)
├── file_split                   # File splitting utility
├── test_docker_delta.sh         # Test script for docker_delta
├── build/
│   ├── dotfiles/.config/        # Shell, editor, and VNC configs
│   ├── kubernetes_configs/      # K8s deployment examples
│   └── scripts/
│       ├── fetch_binaries.sh    # Download GitHub release binaries
│       ├── install_dev_utils.sh # Runtime dev tools installer
│       ├── setup_wsl.sh         # Full WSL2 setup (19 phases)
│       ├── setup_wsl_lite.sh    # Lite WSL2 setup (18 phases)
│       └── setup_dev.sh         # Minimal WSL2 dev setup (8 phases)
└── .github/
    ├── dependabot.yml           # Dependency auto-updates
    └── workflows/               # CI/CD pipelines
```
