# Tasks: Integrate Skopeo with docker_delta for Local Image File Operations

## 1. Research and Analysis
- [ ] 1.1 Explore Skopeo's capabilities and supported formats
- [ ] 1.2 Understand how to extract layers and metadata from local image files
- [ ] 1.3 Test Skopeo commands for inspecting and extracting images
- [ ] 1.4 Compare Skopeo output formats with Docker's save/load format

## 2. Script Enhancement
- [ ] 2.1 Add Skopeo dependency check to `setup_environment` function
- [ ] 2.2 Enhance image source detection logic to check for local files
- [ ] 2.3 Create new function `extract_image_layers_skopeo` for Skopeo-based layer extraction
- [ ] 2.4 Create new function `get_image_manifest_skopeo` for Skopeo-based manifest extraction
- [ ] 2.5 Modify `get_layer_list` to handle Skopeo's manifest format
- [ ] 2.6 Add support for creating deltas between two local image files
- [ ] 2.7 Enhance `apply_delta_package` to support writing to local files

## 3. Command-Line Interface
- [ ] 3.1 Add new option `--source-format` to specify image file format
- [ ] 3.2 Add new option `--target-format` to specify output format
- [ ] 3.3 Add support for `--platform` option for multi-architecture images
- [ ] 3.4 Update usage information and help text

## 4. Testing
- [ ] 4.1 Test delta creation from local Docker archive file
- [ ] 4.2 Test delta application to create local image file
- [ ] 4.3 Test delta creation between two local image files (different versions)
- [ ] 4.4 Test OCI archive format support
- [ ] 4.5 Test Docker daemon fallback behavior
- [ ] 4.6 Verify compatibility with existing functionality
- [ ] 4.7 Test with multi-architecture images (manifest lists)

## 5. Documentation
- [ ] 5.1 Update help text with new options and formats
- [ ] 5.2 Add examples for working with local image files
- [ ] 5.3 Document Skopeo integration and supported formats
- [ ] 5.4 Update dependencies section in help text
