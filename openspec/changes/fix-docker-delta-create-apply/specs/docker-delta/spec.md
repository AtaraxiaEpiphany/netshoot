# Specification: Fix docker_delta create and apply functionality

## Overview

This specification describes the changes made to the `docker_delta` script to fix the issue where it fails to create delta packages from Docker daemon images, particularly with multi-architecture images (manifest lists).

## Problem Statement

The `docker_delta` script was failing to create delta packages from Docker daemon images. The root cause was that it incorrectly tried to extract layers from manifest lists (OCI index files) instead of navigating to the actual image manifests containing layer information.

## Solution

### Key Changes

1. **Enhanced Manifest Processing**: Modified the `get_layer_list()` function to properly handle nested manifest lists
2. **Platform-Aware Manifest Selection**: Added logic to select the appropriate manifest based on platform
3. **Improved Debugging**: Added verbose logging to track manifest processing
4. **Recursive Manifest Handling**: Added support for nested manifest lists

### Modified Function: get_layer_list()

The `get_layer_list()` function was completely rewritten to:

1. **Detect OCI Index**: Identify when processing an OCI index file (`index.json`)
2. **Select Appropriate Manifest**: Choose the correct manifest based on:
   - Explicit platform selection (if specified)
   - Default to amd64/linux when no platform is specified
   - Fallback to first valid manifest if no platform match
3. **Recursive Processing**: Handle nested manifest lists
4. **Extract Layers**: Properly extract layer information from the actual image manifest

### Platform Handling

- Uses existing `--platform` option to specify target OS/ARCH
- Defaults to amd64/linux when no platform is specified
- Provides verbose logging about manifest selection

## New Behavior

### When Processing OCI Index Files

1. The script will now:
   - Verbose log that it's processing an OCI index
   - Look for a manifest matching the specified platform
   - If no platform specified, use amd64/linux
   - If no amd64/linux manifest found, use first valid image manifest
   - Recursively process nested manifest lists
   - Extract layer information from the actual image manifest

### Error Handling

- Provides clear error messages when no valid manifest can be found
- Shows which manifest is being used and why
- Maintains backward compatibility with existing functionality

## Backward Compatibility

- All existing functionality continues to work as before
- Single-architecture images are processed correctly
- Multi-architecture images are now handled properly
- No changes to command-line interface

## Verification

### Test Cases

1. **Single-Architecture Image**: Verify delta creation works with single-architecture images
2. **Multi-Architecture Image**: Verify delta creation works with `hello-world` (multi-arch)
3. **Platform Selection**: Test with explicit platform specification
4. **Nested Manifests**: Test with deeply nested manifest lists

### Expected Outcomes

- The script should successfully create delta packages from Docker daemon images
- The script should handle multi-architecture images correctly
- The script should provide clear debugging information
- No regressions in existing functionality

## Dependencies

- No new external dependencies
- Relies on existing tools: `jq`, `bash`, `docker`, `file_delta`

## Known Limitations

- The script assumes amd64/linux when no platform is specified
- Maximum recursion depth for manifest lists is not explicitly limited
- No support for creating delta packages across different architectures

## Future Enhancements

1. **Explicit Recursion Limit**: Add maximum recursion depth for manifest lists
2. **Multi-Architecture Delta Packages**: Support for creating delta packages across architectures
3. **Better Error Recovery**: Add more robust error recovery for corrupt manifests
4. **Performance Optimization**: Cache manifest processing results
