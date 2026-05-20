# Fix File Compress OOM Issue with Large Files

## Problem Statement
The `file_compress` script experiences OOM (Out of Memory) errors when compressing very large files. This is caused by the script's current approach of buffering entire input contents into temporary files before compression, which consumes excessive memory and disk space for large files.

Users have reported that when using `pv | zstd` directly (without `file_compress`), they see the progress bar stop at times before continuing, indicating periods of high memory usage or buffering.

## Root Cause Analysis
The OOM issue is primarily caused by two key design flaws:

1. **Stdin Buffering (lines 83-86 in `compress()` function)**: When input is received from stdin (`-`), the entire content is read into a temporary file before compression starts
2. **Double Buffering (lines 357-416 in `main()` function)**: Both input and output are buffered through temporary files, causing excessive memory and disk usage

These patterns break true streaming compression and cause the script to consume O(n) memory where n is the file size.

## Solution Approach

### Key Improvements:

1. **True Streaming Compression**: Eliminate temporary file buffering for stdin input and compress data in a streaming fashion

2. **Memory Limits**: Add support for compression tool memory limits (where available)
   - zstd: `--memory=SIZE` option
   - xz: `--memory=SIZE` option
   - gzip/bzip2: No direct memory limit option, but streaming reduces their memory usage

3. **Integrity Verification**: Add optional checksum verification for compressed files
   - SHA-256 checksum generation and verification
   - Compatible with existing compression formats
   - Similar to how `file_split` implements verification

4. **Chunked Processing (Optional)**: For extremely large files, support chunked compression with integrity checks

### Changes Required:

1. Modify the `compress()` function to handle true streaming from stdin
2. Modify the `main()` function to avoid unnecessary temporary file buffering
3. Add checksum verification functionality
4. Add memory limit options for supported compression formats
5. Update usage information and documentation

## Change Impact

- **Risk Level**: Medium (requires architectural changes to the compression pipeline)
- **Scope**: Single file modification in `file_compress` script
- **Testing**: Requires testing with very large files (10GB+), various compression formats, and both file/stdin inputs
- **Backward Compatibility**: No breaking changes - existing functionality remains intact, with new features added as optional

## Success Criteria

1. OOM errors are eliminated when compressing large files
2. Compression works in true streaming mode for stdin input
3. Memory usage is bounded and configurable
4. Checksum verification ensures compressed file integrity
5. Progress tracking continues to work correctly
6. All existing functionality remains intact
7. No performance regression for normal-sized files

## Performance Benefits

- **Memory Usage**: From O(n) to O(1) (constant memory) for streaming compression
- **Disk Usage**: Eliminates temporary file creation for large files
- **Start Time**: Compression begins immediately without waiting for entire input to buffer
