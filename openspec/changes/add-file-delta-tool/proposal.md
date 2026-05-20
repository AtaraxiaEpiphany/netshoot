# OpenSpec Change Proposal: Add File Delta Transform Utility (file_delta)

## Problem Statement

Users need to perform offline incremental upgrades by transferring only the changes (delta data) between different versions of files or directories using USB drives or other limited-bandwidth media. The current Netshoot toolset lacks a dedicated utility for creating and applying delta transforms, which would significantly reduce the amount of data that needs to be transferred.

## Proposed Solution

Add a new `file_delta` utility to the Netshoot toolset that supports:

1. **Multiple Delta Methods**:
   - `xdelta3`: Fast and efficient delta compression for binary files
   - `bsdiff`: High-quality delta compression for large binary files with significant changes
   - `rsync`: Directory synchronization with delta transfer capabilities (preserves permissions, symlinks)

2. **Compression Support**:
   - Compress delta files using zstd (default), gzip, bzip2, or xz
   - Configurable compression levels
   - Support for fast compression modes (zstd --fast)

3. **Core Features**:
   - Create delta from old to new version
   - Apply delta to old version to get new version
   - Handle both single files and directories
   - Dry run mode for testing
   - Force overwrite option
   - Verbose output for debugging

## Implementation Plan

### Core Changes

1. **New Script Creation**: `/home/docker/workspace/git/netshoot/file_delta`
   - Follow existing Netshoot conventions (bash, set -euo pipefail)
   - Color-coded logging (INFO, ERROR, VERBOSE)
   - Usage information with examples
   - Version tracking (VERSION="1.0.0")
   - Dry run mode (-d/--dry-run)
   - Force overwrite option (-f/--force)

2. **Key Functions**:
   - `create_xdelta()` / `apply_xdelta()`: xdelta3 file operations
   - `create_bsdiff()` / `apply_bsdiff()`: bsdiff file operations
   - `create_rsync_delta()` / `apply_rsync_delta()`: rsync directory operations
   - `compress_delta()` / `decompress_delta()`: delta file compression
   - `setup_environment()`: dependency validation

3. **Argument Parsing**:
   - Action: create or apply delta
   - Old path, new path, delta path
   - Method selection (-m/--method: xdelta3, bsdiff, rsync)
   - Compression settings (-c/--compression, -l/--level)
   - Combined short options support (e.g., -vd for verbose dry run)

## Specification

### Syntax

```bash
# Create delta
file_delta create OLD_PATH NEW_PATH DELTA_PATH

# Apply delta
file_delta apply OLD_PATH DELTA_PATH NEW_PATH
```

### Options

```
Actions:
  create    Create delta from OLD_PATH to NEW_PATH, save to DELTA_PATH
  apply     Apply delta from DELTA_PATH to OLD_PATH, save to NEW_PATH

Options:
  -m, --method METHOD        Delta method: xdelta3 (default), bsdiff, rsync
  -c, --compression FORMAT   Compress delta file: zstd (default), gzip, bzip2, xz, none
  -l, --level LEVEL          Compression level (1-9, or -1 to -100 for zstd fast mode)
  -v, --verbose              Show detailed operation info
  -d, --dry-run              Simulate operation without making changes
  -f, --force                Overwrite existing delta/target files
  -h, --help                 Display this help message
  --version                  Show script version
```

### Behavior

**File vs Directory Handling**:
- For single files: Uses xdelta3 or bsdiff (compressed)
- For directories: Uses rsync (preserves permissions, symlinks)
- Automatically detects path type (file/directory)

**Compression**:
- Delta files are compressed by default with zstd level 9
- Supports decompression detection by file extension
- Handles: .gz, .bz2, .xz, .zst, .zstd extensions

## Verification Plan

1. **Basic Functionality Testing**:
   - Test file delta creation and application with xdelta3
   - Test file delta creation and application with bsdiff
   - Test directory delta creation and application with rsync
   - Test compression options (zstd, gzip, bzip2, xz, none)

2. **Edge Case Testing**:
   - Files/directories with spaces in names
   - Empty files and directories
   - Very large files (>1GB)
   - Files with special characters
   - Permission handling

3. **Performance Testing**:
   - Compare delta size vs full file size for various file types
   - Measure delta creation and application times
   - Test with different compression levels

4. **Integration Testing**:
   - Verify compatibility with existing Netshoot tools
   - Test in containerized environment
   - Verify dependencies are available in Netshoot image

## Impact Analysis

### Positive Effects
- Reduces data transfer size for offline upgrades
- Provides multiple delta methods optimized for different scenarios
- Integrates well with existing file_compress and file_split utilities
- Follows Netshoot's design philosophy

### Risks and Mitigations
- **Dependency Requirements**: Requires xdelta3, bsdiff, and rsync (already installed in Netshoot)
- **Disk Space**: Delta operations may require temporary storage (cleanup handled via mktemp)
- **Performance**: Large delta operations may take time (verbose mode provides feedback)

### Backward Compatibility
- Fully backward compatible - new utility adds functionality without changing existing tools
- Uses standard Netshoot conventions for consistent user experience

## Alternatives Considered

1. **Use separate tools directly**: Rejected - lacks unified interface and automation
2. **Extend file_compress**: Rejected - violates Unix philosophy (do one thing well)
3. **Python implementation**: Rejected - bash provides better portability in container environment

## Documentation Updates

1. **Help Text**: Comprehensive usage information with examples
2. **Examples**: Cover common scenarios (single file, directory, different compression options)
3. **Dependencies**: List required tools and optional compression formats

## Timeline

- Implementation: 1 day
- Testing: 1 day
- Documentation: 0.5 day
