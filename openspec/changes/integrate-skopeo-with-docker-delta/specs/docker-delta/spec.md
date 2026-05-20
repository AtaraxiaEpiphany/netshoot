## ADDED Requirements

### Requirement: Skopeo Integration for Local Image File Operations

The `docker_delta` utility SHALL support working with local Docker image files directly without requiring the image to be loaded into the Docker daemon, using Skopeo for image inspection and layer extraction.

#### Scenario: Create delta from local image file
- **WHEN** the user provides a local image file (Docker archive or OCI archive) as source
- **THEN** the script SHALL use Skopeo to inspect and extract the image layers
- **AND** the script SHALL create a delta package from the extracted layers

#### Scenario: Apply delta to local image file
- **WHEN** the user applies a delta package with a local file as target
- **THEN** the script SHALL reconstruct the image layers from the delta
- **AND** the script SHALL use Skopeo to create a local image file from the reconstructed layers

#### Scenario: Create delta between two local image files
- **WHEN** the user specifies two local image files (different versions) as source and target
- **THEN** the script SHALL extract layers from both images
- **AND** the script SHALL create a delta package containing only the changed layers

### Requirement: Support for Multiple Image Formats

The `docker_delta` utility SHALL support reading and writing Docker images in multiple formats supported by Skopeo.

#### Scenario: Read Docker archive format
- **WHEN** the user provides a file in Docker archive format (created with `docker save`)
- **THEN** the script SHALL read and extract image layers correctly

#### Scenario: Read OCI archive format
- **WHEN** the user provides a file in OCI archive format (created with Skopeo)
- **THEN** the script SHALL read and extract image layers correctly

#### Scenario: Write OCI archive format
- **WHEN** the user specifies OCI archive format for output
- **THEN** the script SHALL create a valid OCI archive file

### Requirement: Platform-Specific Image Selection

The `docker_delta` utility SHALL support selecting specific platform images from multi-architecture image files (manifest lists).

#### Scenario: Specify platform for multi-architecture image
- **WHEN** the user provides a multi-architecture image file and specifies a platform
- **THEN** the script SHALL extract the layers for the specified platform
- **AND** the script SHALL create a delta package specific to that platform

#### Scenario: Default platform selection
- **WHEN** the user provides a multi-architecture image file without specifying a platform
- **THEN** the script SHALL default to the current platform (OS/arch)

### Requirement: Fallback to Docker Daemon

The `docker_delta` utility SHALL fall back to using the Docker daemon if Skopeo operations fail or if the image source is not a local file.

#### Scenario: Fallback when source is Docker daemon image
- **WHEN** the user provides an image name/tag that exists in Docker daemon
- **THEN** the script SHALL use Docker daemon operations by default
- **AND** the script SHALL provide the same functionality as before the integration

#### Scenario: Skopeo not available fallback
- **WHEN** Skopeo is not available (e.g., missing dependency) and local file is specified
- **THEN** the script SHALL display an appropriate error message
- **AND** the script SHALL exit with a non-zero exit code

## MODIFIED Requirements

### Requirement: Image Extraction and Analysis

The system SHALL extract and analyze Docker image layers to identify which layers have changed between versions.

#### Scenario: Extract layers from local image file
- **WHEN** extracting layers from a local image file
- **THEN** the system SHALL use Skopeo to copy the image to a temporary directory
- **AND** the system SHALL extract layers directly from the image file
- **AND** the system SHALL verify layer integrity using SHA256 checksums

#### Scenario: Extract layers from Docker daemon
- **WHEN** extracting layers from Docker daemon image
- **THEN** the system SHALL use `docker save` to extract the image
- **AND** the system SHALL extract layers from the resulting tar archive
- **AND** the system SHALL verify layer integrity using SHA256 checksums

### Requirement: Layer Comparison

The system SHALL compare layers between two images to determine which layers have changed.

#### Scenario: Compare layers using Skopeo
- **WHEN** comparing layers of two local image files
- **THEN** the system SHALL use Skopeo to inspect both images
- **AND** the system SHALL extract and compare layer digests from the manifests
- **AND** the system SHALL identify only changed layers for delta creation

#### Scenario: Compare layers using Docker daemon
- **WHEN** comparing layers of two Docker daemon images
- **THEN** the system SHALL use `docker inspect` to get layer information
- **AND** the system SHALL compare layer IDs to identify changed layers
