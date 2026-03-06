# Design Document: Integrate Skopeo with docker_delta

## Context

The current `docker_delta` utility works primarily with Docker images loaded into the local Docker daemon. Users need to work with local image files (Docker archives, OCI archives) without requiring Docker daemon access. Skopeo provides the capability to work with container images directly from files.

### Current Architecture

```
docker_delta
├── Docker Daemon Operations
│   ├── docker save (extract layers)
│   ├── docker inspect (get metadata)
│   └── docker load (reconstruct image)
├── file_delta Integration
│   ├── xdelta3/bsdiff for layer deltas
│   └── compression (zstd, gzip, etc.)
└── Delta Package Format
    ├── manifest.json
    ├── layer_deltas/
    └── metadata.json
```

### Target Architecture

```
docker_delta
├── Image Source Detection
│   ├── Is it a local file? → Skopeo path
│   └── Is it a Docker image? → Docker daemon path
├── Skopeo Operations (NEW)
│   ├── skopeo inspect (get metadata)
│   ├── skopeo copy (extract layers)
│   └── skopeo copy (create local file)
├── Docker Daemon Operations (existing)
│   ├── docker save (extract layers)
│   ├── docker inspect (get metadata)
│   └── docker load (reconstruct image)
├── file_delta Integration
│   ├── xdelta3/bsdiff for layer deltas
│   └── compression (zstd, gzip, etc.)
└── Delta Package Format
    ├── manifest.json
    ├── layer_deltas/
    └── metadata.json
```

## Goals / Non-Goals

### Goals
- Support working with local Docker image files (docker-archive, oci-archive)
- Enable delta creation between two local image files
- Maintain backward compatibility with existing Docker daemon operations
- Support multi-architecture images (manifest lists)
- Provide seamless fallback to Docker daemon when Skopeo is not available

### Non-Goals
- Support for remote registries (Skopeo can do this, but out of scope for docker_delta)
- Image signature verification (Skopeo supports this, but not needed for delta operations)
- Concurrent delta creation for multiple images

## Decisions

### Decision 1: Image Source Detection Strategy

**Approach**: Check if the provided image source exists as a local file. If yes, use Skopeo. If no, assume it's a Docker daemon image name.

**Rationale**: Simple and unambiguous. Users provide file paths for local files and image names/tags for Docker daemon images.

**Implementation**:
```bash
if [[ -f "$image_source" ]]; then
    USE_SKEPEO=1
    IMAGE_FILE="$image_source"
else
    USE_SKEPEO=0
    IMAGE_NAME="$image_source"
fi
```

### Decision 2: Skopeo Transport Format

**Approach**: Support `docker-archive://` and `oci://://` transport formats. Default to `docker-archive://` for files with `.tar` extension.

**Rationale**: Docker archive format is most common (output of `docker save`). OCI archive is a standard format for portability.

**Implementation**:
```bash
detect_format() {
    local file="$1"
    if [[ "$file" == *.tar ]]; then
        echo "docker-archive://$file"
    elif [[ "$file" == *.tar.gz ]] || [[ "$file" == *.tgz ]]; then
        echo "oci-archive://$file"
    else
        echo "docker-archive://$file"  # default
    fi
}
```

### Decision 3: Layer Extraction Strategy

**Approach**: Use `skopeo copy` to extract image layers to a temporary directory in OCI directory format.

**Rationale**: Skopeo's `copy` command can extract layers to a directory, making them accessible for delta operations.

**Implementation**:
```bash
extract_layers_skopeo() {
    local image_file="$1"
    local extract_dir="$2"

    # Copy image to OCI directory format
    skopeo copy \
        --dest-tls-verify=false \
        "docker-archive://$image_file" \
        "oci://$extract_dir"
}
```

### Decision 4: Manifest Extraction

**Approach**: Use `skopeo inspect --raw` to get the full manifest JSON.

**Rationale**: Provides complete manifest information including layer digests and configuration.

**Implementation**:
```bash
get_manifest_skopeo() {
    local image_file="$1"

    skopeo inspect --raw "docker-archive://$image_file"
}
```

### Decision 5: Multi-Architecture Support

**Approach**: Add `--platform` option to specify OS/architecture for manifest list images.

**Rationale**: Multi-architecture images contain manifests for multiple platforms. Users need to specify which platform to use.

**Implementation**:
```bash
skopeo copy \
    --override-arch="$ARCH" \
    --override-os="$OS" \
    "docker-archive://$image_file" \
    "oci://$extract_dir"
```

### Decision 6: Creating Local Image Files from Deltas

**Approach**: Use `skopeo copy` to create a local image file from reconstructed layers.

**Rationale**: Skopeo can create OCI archive or Docker archive files from OCI directory format.

**Implementation**:
```bash
create_image_file() {
    local image_dir="$1"
    local output_file="$2"

    skopeo copy \
        "oci://$image_dir" \
        "docker-archive://$output_file"
}
```

## Alternatives Considered

### Alternative 1: Use Docker Daemon for Everything
**Rejected**: Requires images to be loaded into Docker daemon, which defeats the purpose of working with local files.

### Alternative 2: Parse Docker Archive Format Directly
**Rejected**: Docker archive format is complex (tar within tar). Skopeo already handles this correctly.

### Alternative 3: Create Separate Script for Skopeo Operations
**Rejected**: Would create duplicate code and maintenance burden. Better to integrate into existing script.

## Risks / Trade-offs

### Risk 1: Skopeo Version Compatibility
**Mitigation**: Skopeo is stable and widely used. Netshoot includes a recent version. Document minimum required version.

### Risk 2: Format Compatibility Issues
**Mitigation**: Only support standard formats (docker-archive, oci-archive). Test with common tools (docker save, skopeo copy).

### Risk 3: Performance Overhead
**Mitigation**: Skopeo operations are efficient. Acceptable trade-off for flexibility.

### Risk 4: OCI Directory Format Differences
**Mitigation**: OCI directory format has different structure than Docker tar archive. Handle both formats in layer extraction.

## Migration Plan

### Phase 1: Add Skopeo Detection
- Add Skopeo dependency check
- Add image source detection logic
- No functional changes

### Phase 2: Add Skopeo Extraction
- Implement `extract_layers_skopeo` function
- Implement `get_manifest_skopeo` function
- Test with local image files

### Phase 3: Add Delta Creation Between Files
- Implement comparison logic for two local image files
- Test delta creation between different versions

### Phase 4: Add Local File Output
- Implement `create_image_file` function
- Test delta application to local files

### Phase 5: Add Multi-Architecture Support
- Add `--platform` option
- Test with manifest list images

## Open Questions

1. **Question**: Should we support OCI directory format as intermediate representation?
   **Answer**: Yes, Skopeo uses OCI directory format for extraction. This is the most flexible approach.

2. **Question**: How should we handle images with multiple tags in Docker archive?
   **Answer**: Use the first tag or allow user to specify via new option.

3. **Question**: Should we validate layer integrity after extraction?
   **Answer**: Yes, verify SHA256 checksums to ensure data integrity.

## Implementation Notes

### New Variables
```bash
USE_SKEPEO=0              # Flag for using Skopeo
IMAGE_FILE=""              # Path to local image file
IMAGE_FORMAT=""            # Format: docker-archive, oci-archive
PLATFORM_ARCH=""           # Architecture for multi-arch images
PLATFORM_OS=""            # OS for multi-arch images
```

### New Functions
```bash
detect_image_source()      # Determine if source is file or Docker image
detect_image_format()      # Detect image file format
extract_layers_skopeo()   # Extract layers using Skopeo
get_manifest_skopeo()     # Get manifest using Skopeo
create_image_file()       # Create local image file from layers
compare_image_layers()     # Compare layers between two images
```

### Modified Functions
```bash
setup_environment()         # Add Skopeo dependency check
extract_image_layers()     # Add Skopeo path
get_image_manifest()       # Add Skopeo path
create_delta_package()     # Support two-image delta creation
apply_delta_package()      # Support local file output
parse_args()              # Add new options
usage()                   # Update help text
```

### New Command-Line Options
```bash
--source-format FORMAT      # Specify source format (docker-archive, oci-archive)
--target-format FORMAT      # Specify output format
--platform OS/ARCH         # Specify platform for multi-arch images
```
