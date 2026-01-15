## ADDED Requirements

### Requirement: Progress Bar Display
The `file_compress` script SHALL display a progress bar when compressing files if the `pv` (pipe viewer) tool is available.

#### Scenario: Compress file with progress bar
- **WHEN** the user runs `file_compress` on a file
- **AND** the `pv` tool is available in the system
- **THEN** the script SHALL display a progress bar showing compression progress

#### Scenario: Compress file without progress bar
- **WHEN** the user runs `file_compress` on a file
- **AND** the `pv` tool is not available in the system
- **THEN** the script SHALL compress the file without displaying a progress bar
- **AND** the script SHALL NOT show any error messages related to the missing `pv` tool

#### Scenario: Compress from standard input with progress bar
- **WHEN** the user runs `file_compress` with input from standard input
- **AND** the `pv` tool is available in the system
- **THEN** the script SHALL display a progress bar showing compression progress

### Requirement: Progress Bar Accuracy
The progress bar SHALL accurately reflect the compression progress based on the input size.

#### Scenario: Progress bar for large file
- **WHEN** compressing a large file (several hundred MB or more)
- **THEN** the progress bar SHALL update smoothly and accurately
- **AND** the estimated time remaining SHALL be reasonably accurate

### Requirement: Compatibility with Compression Formats
The progress bar SHALL work with all supported compression formats (zstd, gzip, bzip2, xz).

#### Scenario: Progress bar with zstd compression
- **WHEN** compressing a file with zstd format
- **AND** the `pv` tool is available
- **THEN** the progress bar SHALL be displayed

#### Scenario: Progress bar with gzip compression
- **WHEN** compressing a file with gzip format
- **AND** the `pv` tool is available
- **THEN** the progress bar SHALL be displayed

#### Scenario: Progress bar with bzip2 compression
- **WHEN** compressing a file with bzip2 format
- **AND** the `pv` tool is available
- **THEN** the progress bar SHALL be displayed

#### Scenario: Progress bar with xz compression
- **WHEN** compressing a file with xz format
- **AND** the `pv` tool is available
- **THEN** the progress bar SHALL be displayed
