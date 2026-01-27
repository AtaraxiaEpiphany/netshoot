# OpenSpec Change Proposal: Fix docker_delta layer delta creation and application

## Problem Statement

The `docker_delta` script encounters failures during layer delta creation and application when working with local image files. The main issues are:

1. **Delta creation failure**: When creating a delta package from a local image file (e.g., `hello-world.tar`), the script fails to create layer deltas with the error "Failed to create layer delta".

2. **Manifest format mismatch**: The delta package includes an OCI image manifest that is incompatible with Docker's `load` command, which expects a specific Docker manifest format.

3. **Image tagging issue**: After applying a delta package, the reconstructed image is loaded into Docker but not properly tagged, making it inaccessible by name.

## Root Cause Analysis

1. **Incorrect manifest format detection**: The `get_layer_list()` function was using filename-based detection (checking for `index.json` or `manifest.json`) instead of content-based detection, causing incorrect parsing of OCI image manifests.

2. **Missing Docker-compatible manifest**: The delta package creation process copied the OCI image manifest directly into the delta package, but Docker's `load` command requires a specific Docker manifest format with `Config`, `RepoTags`, and `Layers` fields.

3. **Lack of image tagging**: The `apply_delta_package()` function loaded the reconstructed image but didn't tag it, leaving it only accessible by its SHA256 digest.

## Proposed Solution

1. **Fix manifest format detection**: Modify `get_layer_list()` to detect manifest formats by content (checking for `.manifests` or `.layers` arrays) rather than by filename.

2. **Create Docker-compatible manifest**: Enhance `apply_delta_package()` to generate a Docker-compatible manifest structure that includes the required fields for `docker load`.

3. **Add image tagging**: Implement proper tagging of the loaded image after delta application, ensuring it's accessible by the specified name.

4. **Improve error handling**: Add detailed debugging output and error capture to better diagnose issues during delta creation and application.

## What Changes

### Modified Files
1. `/home/docker/workspace/git/netshoot/docker_delta` - Fix manifest detection, add Docker-compatible manifest creation, improve error handling

### Key Fixes
- **Content-based manifest detection**: Detect OCI index vs OCI image manifest vs Docker manifest by checking content structure
- **Docker manifest generation**: Create Docker-compatible manifest with proper `Config`, `RepoTags`, and `Layers` fields
- **Image tagging**: Tag loaded images with specified name for accessibility
- **Enhanced debugging**: Add verbose output for layer extraction, delta creation, and image loading

### Impact
- **Affected specs**: `docker-delta` capability
- **Affected code**: `/home/docker/workspace/git/netshoot/docker_delta`
- **Backward compatibility**: No breaking changes to existing functionality

## Technical Approach

### Manifest Format Detection Fixes
Replace filename-based detection with content-based detection:
1. Check for `.manifests` array (OCI index)
2. Check for `.layers` array (OCI image manifest)
3. Fallback to Docker manifest parsing

### Docker-compatible Manifest Generation
Create a manifest structure that matches Docker's expectations:
1. `Config`: Path to image configuration blob
2. `RepoTags`: Array of image names/tags
3. `Layers`: Array of layer file paths

### Image Tagging Enhancement
After `docker load`, extract the loaded image ID and tag it with the specified name to ensure accessibility.

## Implementation Plan

### Tasks

1. **Fix manifest format detection in get_layer_list()**:
   - Replace filename checks with content-based detection
   - Add verbose logging for format detection
   - Test with OCI index, OCI image manifest, and Docker manifest

2. **Create Docker-compatible manifest in apply_delta_package()**:
   - Generate manifest with required Docker fields
   - Handle layer path formatting for Docker compatibility
   - Add index.json and oci-layout files for Docker compatibility

3. **Add image tagging after delta application**:
   - Extract loaded image ID from `docker load` output
   - Tag image with specified name if provided
   - Fallback to using image ID if no name specified

4. **Enhance error handling and debugging**:
   - Add detailed verbose output for delta creation and application
   - Capture and log error output from subprocesses
   - Add validation for layer file existence and readability

5. **Test end-to-end workflow**:
   - Test delta creation from local image file
   - Test delta application and image reconstruction
   - Verify image functionality after reconstruction

## Verification Plan

1. **Basic Functionality**:
   - Create delta package from `hello-world.tar`
   - Remove original image from Docker daemon
   - Apply delta package to reconstruct image
   - Verify image is accessible by name and runs correctly

2. **Manifest Format Handling**:
   - Verify correct detection of OCI index files
   - Verify correct detection of OCI image manifests
   - Verify correct handling of Docker manifests

3. **Image Tagging**:
   - Verify loaded image is properly tagged
   - Verify image can be accessed by specified name
   - Verify `docker run` works with reconstructed image

4. **Error Handling**:
   - Test error scenarios (missing files, permission issues)
   - Verify informative error messages
   - Verify graceful exit with appropriate exit codes

## Risks and Mitigations

- **Manifest format complexity**: OCI and Docker formats have subtle differences. Mitigation: Use content-based detection and thorough testing.
- **Docker version compatibility**: Different Docker versions may have slightly different manifest expectations. Mitigation: Test with common Docker versions.
- **Image tagging failures**: `docker tag` may fail if the image ID is incorrect. Mitigation: Validate image ID before tagging and provide fallback.

## Backward Compatibility

The changes are backward compatible:
- Existing functionality for Docker daemon images continues to work
- Local image file operations gain improved reliability
- No changes to command-line interface or behavior

## Documentation Updates

- Update script help text with improved error handling details
- Add examples for working with local image files
- Document manifest format detection improvements

## Timeline

- Implementation and Testing: 2 days
- Verification and Documentation: 1 day