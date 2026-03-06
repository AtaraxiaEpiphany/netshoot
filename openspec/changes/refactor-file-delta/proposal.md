# OpenSpec Change Proposal: Refactor file_delta Script

## Problem Statement

The `file_delta` script (v1.0.0) is functionally complete but has opportunities for improved code structure, readability, and maintainability. While it follows Netshoot conventions, the script would benefit from:

1. **Code Organization**: Functions are grouped but could be better organized by concern (delta methods, compression, path handling, validation)
2. **Error Handling**: Some error handling could be more granular with specific error codes
3. **Configuration Management**: Settings are scattered throughout the script and could be centralized
4. **Code Duplication**: The rsync command building logic is duplicated in `create_rsync_delta` and `apply_rsync_delta`
5. **Function Naming**: Some function names could be more descriptive
6. **Constants**: Magic numbers and repeated strings could be extracted to constants

## Proposed Solution

Refactor the `file_delta` script to improve code structure and readability while maintaining 100% functional compatibility. The refactor will:

1. **Reorganize Functions by Concern**:
   - Configuration and constants section
   - Logging functions section
   - Validation functions section
   - Delta method functions section (xdelta3, bsdiff, rsync)
   - Compression functions section
   - Path handling functions section
   - Core operations section (create_delta, apply_delta)
   - CLI interface section (parse_args, usage, main)

2. **Extract Constants**:
   - Compression level ranges
   - Supported methods and formats
   - Error messages

3. **Eliminate Code Duplication**:
   - Create a shared `build_rsync_command()` function
   - Consolidate similar validation logic

4. **Improve Error Handling**:
   - Add exit codes for different error scenarios
   - More descriptive error messages

5. **Enhance Code Documentation**:
   - Add section comments for better navigation
   - Improve inline comments where needed

## Implementation Plan

### Core Changes

1. **Constants Section** (after version variable):
   ```bash
   # Constants
   SUPPORTED_METHODS="xdelta3|bsdiff|rsync"
   SUPPORTED_COMPRESSION="zstd|gzip|bzip2|xz|none"
   ZSTD_MIN_LEVEL=-100
   ZSTD_MAX_LEVEL=22
   STD_MIN_LEVEL=1
   STD_MAX_LEVEL=9
   ```

2. **Reorganized Function Sections**:
   - Logging functions: `error()`, `verbose()`, `info()`
   - Utility functions: `command_exists()`, `get_path_type()`
   - Validation functions: `validate_inputs()`, `validate_compression_level()`, `validate_paths()`
   - Delta method functions: xdelta3, bsdiff, rsync (create/apply pairs)
   - Compression functions: `compress_delta()`, `decompress_delta()`, `detect_compression_format()`
   - Rsync helpers: `build_rsync_command()`
   - Core operations: `create_delta()`, `apply_delta()`
   - CLI interface: `parse_args()`, `usage()`, `main()`

3. **New Helper Functions**:
   - `build_rsync_command()`: Shared rsync command building logic
   - `validate_compression_level()`: Centralized compression level validation
   - `detect_compression_format()`: Extract compression detection logic

4. **Exit Codes**:
   ```bash
   EXIT_SUCCESS=0
   EXIT_ERROR=1
   EXIT_MISSING_DEPS=2
   EXIT_INVALID_INPUT=3
   EXIT_OPERATION_FAILED=4
   ```

## Specification

### Invariants

1. **Functional Compatibility**: All existing functionality must be preserved
2. **CLI Compatibility**: All command-line options and behavior must remain identical
3. **Output Compatibility**: All output messages and formats must remain identical
4. **Exit Behavior**: Exit codes and error messages must remain identical

### Behavior Changes

**None** - This is a pure refactor with no behavioral changes.

## Verification Plan

1. **Functional Testing**:
   - Verify all delta methods (xdelta3, bsdiff, rsync) work identically
   - Verify all compression formats work identically
   - Verify all CLI options work identically
   - Verify error handling works identically

2. **Regression Testing**:
   - Compare output of old and new script for all test cases
   - Verify exit codes match for all scenarios
   - Verify error messages match

3. **Code Quality**:
   - Verify no code duplication
   - Verify all functions are properly organized
   - Verify constants are used consistently

## Impact Analysis

### Positive Effects
- Improved code maintainability
- Easier to add new features in the future
- Better code organization for developers
- Reduced code duplication

### Risks and Mitigations
- **Regression Risk**: Comprehensive testing will ensure no functional changes
- **Review Effort**: The refactor is purely structural, making review straightforward

### Backward Compatibility
- Fully backward compatible - no functional or CLI changes
- All existing scripts and workflows will continue to work

## Alternatives Considered

1. **Rewrite in Python**: Rejected - would break compatibility and increase dependencies
2. **Split into multiple files**: Rejected - would complicate deployment in container environment
3. **No refactor**: Rejected - code quality improvements are valuable for long-term maintainability

## Documentation Updates

1. **Internal Documentation**: Improved code comments and section organization
2. **No User Documentation Changes**: External behavior is unchanged

## Timeline

- Refactoring: 0.5 day
- Testing: 0.5 day
