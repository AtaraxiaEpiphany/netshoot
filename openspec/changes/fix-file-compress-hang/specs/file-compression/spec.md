# File Compression Specification Delta

## MODIFIED Requirements

#### Requirement: Compression Commands Must Properly Handle Standard Input
**Modified from**: Basic compression command execution
**Modified to**: Compression commands must include stdin/stdout redirection arguments

#### Scenario: Compressing from Standard Input
- **Given** the file_compress script is processing input from stdin
- **When** any compression format (zstd, gzip, bzip2, xz) is used
- **Then** the compression command must include the `-` argument to read from stdin
- **And** the compression process must complete without hanging
- **And** the output must be written to stdout

#### Scenario: Compressing from File Input
- **Given** the file_compress script is processing input from a file
- **When** any compression format is used
- **Then** the compression command must include the `-` argument for consistency
- **And** the compression process must complete successfully
- **And** the output must be written to the specified destination

#### Scenario: Pipeline Integration
- **Given** the file_compress script is used in a pipeline
- **When** input is piped from another command
- **Then** the compression process must read from the pipe without hanging
- **And** the output must be piped to the next command correctly

## ADDED Requirements

#### Requirement: Robust Standard Input/Output Handling
**Added to ensure**: Compression tools properly integrate with Unix pipelines

#### Scenario: Progress Tracking with Standard Input
- **Given** progress tracking is enabled (pv available)
- **When** compressing from stdin
- **Then** the progress bar must display correctly
- **And** the compression must complete without interruption

#### Scenario: Error Handling with Standard Input
- **Given** invalid input is provided via stdin
- **When** compression is attempted
- **Then** the script must handle the error gracefully
- **And** appropriate error messages must be displayed

## Technical Implementation Details

### Command Format Updates
All compression commands in the `compress()` function must be updated:

- **gzip**: `gzip -$level` → `gzip -$level -`
- **bzip2**: `bzip2 -$level` → `bzip2 -$level -`
- **xz**: `xz -$level` → `xz -$level -`
- **zstd**: `zstd $zstd_opts --threads=$threads` → `zstd $zstd_opts --threads=$threads -`

### Validation Requirements
- Script must be tested with both file and stdin inputs
- All compression formats must be verified
- Pipeline usage must be validated
- Error conditions must be tested