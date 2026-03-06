# OpenSpec Change Proposal: Integrate Skopeo with docker_delta for Local Image File Operations

## Problem Statement

The current `docker_delta` utility primarily works with Docker images that are already loaded into the local Docker daemon. This approach has limitations when working in environments where:

1. Docker images are stored as local tar files (e.g., from `docker save` or `skopeo copy`) and haven't been loaded into the Docker daemon
2. Users need to create deltas between different versions of images stored as local files
3. There are constraints on loading images into the Docker daemon (e.g., disk space, permissions, or security restrictions)

## Why Skopeo?

Skopeo is a powerful tool for working with container images and registries that supports:
- Direct operations on local image files without requiring Docker daemon
- Reading and writing images in various formats (docker-archive, oci-archive, dir)
- Extracting image manifests and layer information
- Verifying image signatures and integrity
- Efficient image copying and synchronization

## Proposed Solution

Enhance the `docker_delta` script to integrate with Skopeo to support:

1. **Direct Local Image File Operations**:
   - Read Docker images directly from local tar files (docker-archive format)
   - Write images directly to local files without loading them into Docker daemon
   - Support for OCI archive format in addition to Docker archive format

2. **Delta Creation Between Local Image Files**:
   - Create deltas between two local image files (different versions)
   - Identify changed layers by comparing image manifests and layer digests
   - Efficient delta creation using existing file_delta capabilities

3. **Skopeo Integration**:
   - Use Skopeo to inspect images and extract metadata
   - Use Skopeo to copy and extract image layers
   - Support for various transport formats supported by Skopeo

4. **Enhanced Layer Detection**:
   - Improved layer comparison using Skopeo's manifest analysis
   - Better handling of shared layers between images
   - Support for multi-architecture images (manifest lists)

## What Changes

### Modified Files
1. `/home/docker/workspace/git/netshoot/docker_delta` - Enhanced with Skopeo integration

### Key Features Added
- Support for `skopeo` as an optional dependency for local image file operations
- New command-line options for specifying image sources as files
- Enhanced manifest parsing using Skopeo's `inspect` command
- Layer extraction and comparison directly from image files
- Optional Docker daemon bypass for offline operations

### Impact
- Affected specs: `docker-delta` capability
- Affected code: `/home/docker/workspace/git/netshoot/docker_delta`
- No breaking changes to existing functionality - Skopeo integration is optional

## Technical Approach

### Image Source Detection
The script will detect if an image source is a local file by checking if it exists on disk. If so, Skopeo will be used to inspect and extract the image.

### Manifest Extraction
Use `skopeo inspect` to get detailed image metadata instead of `docker inspect` when working with local files.

### Layer Extraction
Use `skopeo copy` to extract image layers to a temporary directory for delta operations.

### Architecture Support
Handle manifest lists for multi-architecture images and allow users to specify platform.

## Implementation Plan

### Tasks

1. **Research and Analysis**:
   - Explore Skopeo's capabilities and supported formats
   - Understand how to extract layers and metadata from local image files

2. **Modify docker_delta Script**:
   - Add Skopeo dependency check
   - Enhance image source detection logic
   - Add Skopeo-based manifest extraction
   - Add Skopeo-based layer extraction
   - Modify layer comparison logic to work with local files
   - Add support for creating deltas between two local image files
   - Update documentation and help text

3. **Testing**:
   - Test with Docker archive files (.tar) created with `docker save`
   - Test with OCI archive files (.tar.gz) created with Skopeo
   - Test delta creation between different image versions
   - Test applying deltas to local image files
   - Test Docker daemon vs. Skopeo-based operations

## Risks and Mitigations

- **Dependency on Skopeo**: Skopeo is already included in Netshoot image (line 94 of Dockerfile), so no additional installation required
- **Format Compatibility**: Only supports formats that Skopeo can read (docker-archive, oci-archive, oci-dir)
- **Performance**: Skopeo operations may be slower than Docker daemon, but provide more flexibility

## Backward Compatibility

The changes are backward compatible:
- Existing functionality continues to work as before
- Skopeo integration is optional and only used when local image files are specified
- Users can still work with Docker daemon images as before

## Alternatives Considered

- **Extending docker save/load**: Would require Docker daemon and has limitations
- **Using other tools**: Skopeo is the most appropriate tool given its capabilities and existing inclusion in Netshoot

## Documentation Updates

- Update help text with new options
- Add examples for working with local image files
- Document Skopeo integration and supported formats

## Verification Plan

1. **Basic Functionality**:
   - Create delta from local image file
   - Apply delta to reconstruct local image file
   - Create delta between two local image files
   - Verify delta package content

2. **Format Support**:
   - Test with Docker archive format (docker save output)
   - Test with OCI archive format (Skopeo output)
   - Test with OCI directory format

3. **Multi-Architecture Support**:
   - Test with manifest list images
   - Test specifying platform parameters

4. **Performance**:
   - Compare Skopeo-based operations with Docker daemon operations
   - Test with large images

## Timeline

- Implementation: 3 days
- Testing: 2 days
- Documentation: 1 day
