# OpenSpec Change Proposal: Fix docker_delta create and apply functionality

## Problem Statement

The current `docker_delta` script fails to create delta packages from Docker daemon images. When running the `create` action on a Docker image like `hello-world`, the script detects the image correctly but fails to create layer deltas. The error message "Failed to create layer delta" indicates an issue with layer extraction or delta creation process.

## Root Cause Analysis

1. **Image Extraction Issue**: The `docker save` command produces a tar archive with a specific structure. The current script might not be correctly extracting or identifying layer files from this archive.
2. **Layer Path Resolution**: When using Docker daemon images, the layer files are stored in a different format compared to local image files processed via Skopeo.
3. **Layer Delta Creation**: The script's layer handling logic might not properly map the extracted layer paths to the expected locations for the `file_delta` utility.

## Proposed Solution

1. **Fix Image Extraction**: Verify and correct the logic for extracting layer files from `docker save` tar archives
2. **Improve Layer Path Handling**: Ensure layer files are correctly identified and their paths are properly normalized
3. **Debug and Test**: Add more detailed debugging information and test the script with small, simple images like `hello-world`

## What Changes

### Modified Files
1. `/home/docker/workspace/git/netshoot/docker_delta` - Fix layer extraction and delta creation logic

### Key Fixes
- Improve layer path detection from `docker save` output
- Fix layer file resolution when using Docker daemon images
- Add more detailed debugging information
- Fix the integration between `extract_image_layers` and `create_layer_delta` functions

## Technical Approach

### Image Extraction Fixes
When using `docker save`, the output tar archive structure has changed over time. Recent Docker versions save in OCI format by default, which has a different layer storage structure compared to the legacy Docker format.

The script needs to properly handle both formats:
1. Legacy Docker format: layer directories named by their SHA256 hash
2. OCI format: layers stored in `blobs/sha256/` directory

### Layer Path Resolution Fixes
The current layer handling logic assumes a specific directory structure that might not match the actual output of `docker save`. We need to:
1. Check for different layer storage formats
2. Normalize layer paths for consistent processing
3. Verify layer file existence before attempting delta creation

## Implementation Plan

### Tasks

1. **Analyze Current Image Extraction**: Examine the layer extraction process with `docker save hello-world`
2. **Fix Layer Detection**: Improve layer path detection logic in `get_layer_list` function
3. **Fix Delta Creation**: Ensure `create_layer_delta` function receives valid layer file paths
4. **Test with hello-world Image**: Verify the fix by creating and applying a delta package for `hello-world:latest`
5. **Debug Information**: Add more detailed debugging output to track layer paths through the process

## Verification Plan

1. **Basic Functionality**:
   - Test delta creation from `hello-world` Docker daemon image
   - Test delta application to reconstruct the image
   - Verify the reconstructed image matches the original

2. **Layer Handling**:
   - Verify layer extraction from `docker save` tar archive
   - Check layer file path resolution
   - Ensure layer delta files are created correctly

3. **Format Compatibility**:
   - Test with legacy Docker format images
   - Test with OCI format images (default in Docker 17.06+)

## Timeline

- Implementation and Testing: 1 day
- Verification: 1 day
