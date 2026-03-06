# OpenSpec Change Proposal: Add Docker Image Delta Transfer Utility (docker_delta)

## Problem Statement

Users need to transfer Docker images between systems using USB drives or other limited-bandwidth media in offline environments. Currently, transferring Docker images requires saving the entire image as a tar archive using `docker save`, which transfers all layers even if some layers already exist on the target system. This is inefficient when:
- Only a few layers have changed between image versions
- The target system already has some shared base layers
- Transfer bandwidth is limited (USB drives, air-gapped networks)

The existing `file_delta` utility works for regular files and directories, but Docker images have a layered structure that requires specialized handling to efficiently transfer only changed layers.

## Proposed Solution

Add a new `docker_delta` utility to the Netshoot toolset that enables efficient Docker image transfer by:

1. **Layer-Aware Delta Operations**:
   - Extract and analyze Docker image layers
   - Identify which layers already exist on the target system
   - Transfer only the missing or changed layers
   - Reconstruct the complete image on the target system

2. **Integration with file_delta**:
   - Use xdelta3/bsdiff for layer content delta when appropriate
   - Leverage existing compression capabilities (zstd, gzip, etc.)
   - Support layer-by-layer delta creation and application

3. **Manifest and Configuration Handling**:
   - Extract and transfer image manifests
   - Handle layer digests and checksums
   - Preserve image metadata (labels, environment variables, etc.)

4. **Core Features**:
   - Create delta package from source Docker image
   - Apply delta package to reconstruct image on target
   - Dry run mode to preview transfer size
   - Verbose output for debugging
   - Force overwrite option

## Implementation Plan

### Core Changes

1. **New Script Creation**: `/home/docker/workspace/git/netshoot/docker_delta`
   - Follow existing Netshoot conventions (bash, set -euo pipefail)
   - Color-coded logging (INFO, ERROR, VERBOSE)
   - Usage information with examples
   - Version tracking (VERSION="1.0.0")
   - Dry run mode (-d/--dry-run)
   - Force overwrite option (-f/--force)

2. **Key Functions**:
   - `extract_image_layers()`: Extract Docker image layers to temporary directory
   - `get_layer_manifest()`: Parse image manifest to get layer information
   - `create_layer_delta()`: Create delta for each layer using file_delta
   - `apply_layer_delta()`: Apply delta to reconstruct layers
   - `reconstruct_image()`: Rebuild Docker image from layers
   - `create_delta_package()`: Package all layer deltas and manifest
   - `extract_delta_package()`: Extract delta package for application

3. **Docker Image Structure Handling**:
   - Parse `docker save` tar format
   - Extract manifest.json and layer files
   - Handle layer chain IDs and digests
   - Validate layer integrity

4. **Argument Parsing**:
   - Action: create or apply delta
   - Source image name/tag
   - Delta package path
   - Compression settings (-c/--compression, -l/--level)
   - Delta method selection (-m/--method: xdelta3, bsdiff, layer)

### Docker Image Format Understanding

Docker images saved with `docker save` produce a tar archive containing:
- `manifest.json`: Image manifest with layer references
- `repositories`: Image repository tags
- Layer files: Named by their SHA256 hash (e.g., `sha256:abc123...`)

The delta package will contain:
- `manifest.json`: Original image manifest
- `layer_deltas/`: Directory containing delta files for each layer
- `metadata.json`: Delta package metadata (version, compression, etc.)

## Specification

### Syntax

```bash
# Create delta package from Docker image
docker_delta create IMAGE_NAME DELTA_PACKAGE

# Apply delta package to reconstruct Docker image
docker_delta apply DELTA_PACKAGE [IMAGE_NAME]

# List layers in delta package
docker_delta list DELTA_PACKAGE

# Show delta package info
docker_delta info DELTA_PACKAGE
```

### Options

```
Actions:
  create    Create delta package from Docker image
  apply     Apply delta package to reconstruct image
  list      List layers in delta package
  info      Show delta package metadata

Options:
  -m, --method METHOD        Delta method: xdelta3 (default), bsdiff, layer
  -c, --compression FORMAT   Compress delta: zstd (default), gzip, bzip2, xz, none
  -l, --level LEVEL          Compression level (1-9, or -1 to -100 for zstd fast mode)
  -v, --verbose              Show detailed operation info
  -d, --dry-run              Simulate operation without making changes
  -f, --force                Overwrite existing delta/target files
  -h, --help                 Display this help message
  --version                  Show script version
```

### Behavior

**Delta Method Selection**:
- `xdelta3`: Create binary delta for each layer (smallest transfer size)
- `bsdiff`: Create bsdiff delta for each layer (good for large changes)
- `layer`: Transfer complete layer files (no delta, just compression)

**Layer Detection**:
- Extract image manifest to identify all layers
- Check if layers exist on target system (optional, requires docker inspect)
- Only transfer missing layers when using apply with existing image

**Compression**:
- Delta packages are compressed by default with zstd level 9
- Layer deltas use file_delta compression settings
- Final package can be further compressed for transfer

## Verification Plan

1. **Basic Functionality Testing**:
   - Test delta creation from simple Docker image
   - Test delta application to reconstruct image
   - Verify reconstructed image matches original source
   - Test compression options (zstd, gzip, bzip2, xz, none)

2. **Layer Handling Testing**:
   - Test with multi-layer images
   - Test with images sharing base layers
   - Verify layer integrity after transfer
   - Test manifest preservation

3. **Delta Method Testing**:
   - Test xdelta3 delta for layer content
   - Test bsdiff delta for layer content
   - Test layer-only transfer (no delta)
   - Compare transfer sizes between methods

4. **Edge Case Testing**:
   - Empty layers
   - Very large images (>1GB)
   - Images with many layers (>50)
   - Images with custom metadata

5. **Integration Testing**:
   - Test with file_delta utility
   - Verify compatibility with docker load/save
   - Test in containerized environment
   - Verify dependencies are available in Netshoot image

## Impact Analysis

### Positive Effects
- Dramatically reduces Docker image transfer size for offline environments
- Enables efficient incremental Docker image updates via USB
- Integrates with existing file_delta utility
- Follows Netshoot's design philosophy
- Supports air-gapped system maintenance

### Risks and Mitigations
- **Dependency Requirements**: Requires docker CLI, tar, file_delta (already available)
- **Disk Space**: Delta operations may require temporary storage (cleanup handled via mktemp)
- **Layer Integrity**: Validate layer digests to ensure transfer accuracy
- **Docker Version**: May have compatibility issues across Docker versions (use standard tar format)

### Backward Compatibility
- Fully backward compatible - new utility adds functionality without changing existing tools
- Uses standard Docker save/load tar format for maximum compatibility
- Integrates with existing file_delta utility

## Alternatives Considered

1. **Use docker save/load directly**: Rejected - transfers all layers, inefficient for incremental updates
2. **Use skopeo**: Rejected - additional dependency, not designed for USB transfer
3. **Extend file_delta for Docker**: Rejected - Docker images have special structure requiring dedicated handling
4. **Python implementation**: Rejected - bash provides better portability in container environment

## Documentation Updates

1. **Help Text**: Comprehensive usage information with examples
2. **Examples**: Cover common scenarios (single image, multi-layer, different delta methods)
3. **Dependencies**: List required tools (docker, tar, file_delta)
4. **Use Cases**: Document offline transfer workflows

## Timeline

- Implementation: 2 days
- Testing: 2 days
- Documentation: 1 day
