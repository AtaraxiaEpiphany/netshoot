# Design Document: Fix docker_delta layer delta creation and application

## Problem Overview

The `docker_delta` script has three main issues when working with local image files:

1. **Manifest format detection failure**: The script incorrectly identifies manifest formats based on filename rather than content, leading to parsing errors.

2. **Docker compatibility issue**: Delta packages contain OCI format manifests that are incompatible with Docker's `load` command.

3. **Image accessibility problem**: Reconstructed images are not properly tagged, making them inaccessible by name.

## Design Goals

1. **Reliable manifest detection**: Correctly identify and parse all supported manifest formats.
2. **Docker compatibility**: Ensure delta packages can be loaded by Docker without errors.
3. **User accessibility**: Make reconstructed images easily accessible by name.
4. **Improved debuggability**: Provide detailed logging for troubleshooting.

## Architecture Changes

### Current Architecture
```
Image Source Detection
    ↓
Extract Layers (Docker daemon or Skopeo)
    ↓
Create Layer Deltas (file_delta)
    ↓
Package Delta Files
    ↓
Apply Delta (extract, reconstruct, load)
```

### Proposed Architecture
```
Image Source Detection
    ↓
Content-Based Manifest Analysis
    ↓
Extract Layers with Format Awareness
    ↓
Create Layer Deltas with Enhanced Error Handling
    ↓
Package with Docker-Compatible Manifest
    ↓
Apply Delta with Tagging and Validation
```

## Component Design

### 1. Manifest Format Detector

**Purpose**: Detect and parse Docker image manifest formats by content.

**Input**: Manifest file path
**Output**: Manifest type (OCI_INDEX, OCI_IMAGE, DOCKER_MANIFEST) and parsed data

**Algorithm**:
1. Read manifest file
2. Parse JSON
3. Check for `.manifests` array → OCI_INDEX
4. Check for `.layers` array → OCI_IMAGE
5. Check for `Layers` array → DOCKER_MANIFEST
6. Return type and parsed data

**Error Handling**:
- Invalid JSON → error with line number
- Missing required fields → error with specific field name
- Unsupported format → error with format details

### 2. Docker-Compatible Manifest Generator

**Purpose**: Convert OCI manifests to Docker-compatible format.

**Input**: OCI image manifest
**Output**: Docker manifest JSON

**Transformation Rules**:
- OCI `.config.digest` → Docker `Config` path
- OCI `.layers[].digest` → Docker `Layers` paths
- Target image name → Docker `RepoTags` array

**Output Format**:
```json
[{
  "Config": "blobs/sha256/<config_digest>",
  "RepoTags": ["image:tag"],
  "Layers": ["blobs/sha256/<layer_digest>", ...]
}]
```

### 3. Image Tagging Manager

**Purpose**: Tag reconstructed images for accessibility.

**Input**: `docker load` output, target image name
**Output**: Tagged Docker image

**Process**:
1. Parse `docker load` output for image ID
2. Validate image ID format
3. Execute `docker tag <image_id> <target_name>`
4. Verify tagging success
5. Provide user feedback

**Fallback Strategy**:
- If tagging fails, display image ID for manual tagging
- Provide clear instructions for manual tagging
- Exit with appropriate warning code

## Data Flow

### Delta Creation Flow
```
Local Image File
    ↓
Content-Based Manifest Detection
    ↓
Layer Extraction (Skopeo)
    ↓
Delta Creation (file_delta)
    ↓
Package Assembly
    ↓
Delta Package Output
```

### Delta Application Flow
```
Delta Package
    ↓
Extraction and Validation
    ↓
Layer Reconstruction (file_delta)
    ↓
Docker-Compatible Manifest Generation
    ↓
Image Tar Creation
    ↓
Docker Load and Tagging
    ↓
Accessible Docker Image
```

## Trade-off Analysis

### Trade-off 1: Content vs Filename Detection

**Option A (Current)**: Filename-based detection
- Pros: Simple implementation
- Cons: Brittle, fails with non-standard filenames

**Option B (Proposed)**: Content-based detection
- Pros: Robust, handles any filename
- Cons: Requires JSON parsing, slightly more complex

**Decision**: Option B - Robustness outweighs complexity

### Trade-off 2: Manifest Format Support

**Option A**: OCI-only format
- Pros: Simpler code, single format
- Cons: Not compatible with Docker `load`

**Option B**: Dual-format support
- Pros: Full Docker compatibility
- Cons: More complex transformation logic

**Decision**: Option B - User experience is priority

### Trade-off 3: Error Handling Granularity

**Option A**: Basic error messages
- Pros: Simple implementation
- Cons: Difficult troubleshooting

**Option B**: Detailed error reporting
- Pros: Easier debugging, better user support
- Cons: More verbose output, larger code

**Decision**: Option B - Debuggability is critical for complex operations

## Implementation Strategy

### Phase 1: Core Fixes
1. Implement content-based manifest detection
2. Fix layer delta creation error handling
3. Add verbose logging for troubleshooting

### Phase 2: Docker Compatibility
1. Generate Docker-compatible manifests
2. Create required auxiliary files
3. Test `docker load` compatibility

### Phase 3: User Experience
1. Implement image tagging
2. Add validation and verification
3. Improve error messages and documentation

## Testing Strategy

### Unit Tests
- Manifest format detection tests
- Manifest transformation tests
- Error handling tests

### Integration Tests
- End-to-end delta creation and application
- Docker compatibility tests
- Cross-format conversion tests

### Acceptance Tests
- User workflow tests
- Error scenario tests
- Performance and reliability tests

## Migration Plan

### Step 1: Implement without breaking changes
- Add new functionality alongside existing code
- Maintain backward compatibility
- Test with existing workflows

### Step 2: Gradual rollout
- Enable new features with configuration flags
- Gather user feedback
- Monitor for issues

### Step 3: Full adoption
- Make new behavior default
- Deprecate old code paths
- Update documentation

## Risk Assessment

### High Risk
- **Manifest transformation errors**: Could corrupt images
- **Mitigation**: Extensive testing with diverse image formats
- **Rollback**: Keep original code path as fallback

### Medium Risk
- **Performance impact**: Additional parsing overhead
- **Mitigation**: Optimize JSON parsing, cache results
- **Monitoring**: Track performance metrics



### Low Risk
- **Increased verbosity**: More logging output
- **Mitigation**: Configurable logging levels
- **Documentation**: Explain new output format

## Success Metrics

1. **Delta creation success rate**: >99% for supported formats
2. **Delta application success rate**: >99% for valid delta packages
3. **Image accessibility**: 100% of reconstructed images accessible by name
4. **Error resolution time**: Reduced troubleshooting time by 50%
5. **User satisfaction**: Positive feedback on error messages and reliability

## Future Considerations

1. **Additional manifest formats**: Support for new container standards
2. **Performance optimization**: Parallel processing for large images
3. **Enhanced validation**: Checksum verification for reconstructed images
4. **Cloud integration**: Direct delta creation from container registries