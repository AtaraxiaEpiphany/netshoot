# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> For full project documentation, see [README.md](README.md).

## Table of Contents

- [Build & CI](#build--ci) — make targets, Docker image naming, CI/CD pipeline
- [Architecture](#architecture) — multi-stage Dockerfile, layer optimization
- [Utility Scripts](#utility-scripts) — docker_delta, file_compress, file_delta, file_split
- [Setup Scripts](#setup-scripts) — WSL2 setup scripts (full/lite/dev)
- [Kubernetes Examples](#kubernetes-examples) — sidecar and Calico debugging manifests
- [Script Conventions](#script-conventions) — patterns all bash scripts follow

## Build & CI

```bash
make build-x86        # linux/amd64
make build-arm64      # linux/arm64
make build-all        # both via buildx
make all              # build-all + push
bash test_docker_delta.sh   # test docker_delta
```

Image: `nicolaka/netshoot:0.1`. PRs to `master` trigger build test; `v*` tags trigger release to Docker Hub + GHCR.

## Architecture

Two-stage Dockerfile — see [README.md: Architecture](README.md#architecture) for details.

- **Stage 1 (fetcher)**: downloads 7 binaries from GitHub releases
- **Stage 2 (main)**: single-layer apt install (~100+ packages), copies binaries + dotfiles, runs `install_dev_utils.sh`

## Utility Scripts

Standalone bash executables at repo root. All support `--dry-run`, `--verbose`, `--help`.

| Script | Version | Description |
|--------|---------|-------------|
| `docker_delta` | 1.0.0 | Docker image delta transfer (xdelta3/bsdiff/layer methods + Skopeo) |
| `file_compress` | 1.2.0 | Multi-format compression (zstd/gzip/bzip2/xz) with progress + SHA-256 |
| `file_delta` | 1.0.0 | File/directory delta using xdelta3/bsdiff/rsync |
| `file_split` | — | File splitting with manifest + SHA-256 checksum verification |

## Setup Scripts

Located in `build/scripts/`. All support checkpoint/resume.

| Script | Phases | Use Case |
|--------|--------|----------|
| `setup_wsl.sh` | 19 | Full air-gapped WSL2 export |
| `setup_wsl_lite.sh` | 18 | Lite setup, deferred apt to post-import |
| `setup_dev.sh` | 8 | Minimal dev env with fish shell |

Other scripts: `fetch_binaries.sh` (GitHub release downloader), `install_dev_utils.sh` (runtime dev tools installer).

## Kubernetes Examples

`build/kubernetes_configs/`:
- `netshoot-sidecar.yaml` — sidecar pattern alongside nginx
- `netshoot-calico.yaml` — Calico network debugging with hostNetwork + etcd secrets

## Script Conventions

All bash scripts: `set -euo pipefail`, `VERSION` var, `--dry-run`/`-d`, `--verbose`/`-v`, color-coded logging (`log_info`/`log_error`/`log_verbose`), combined short options (`-vd`).
