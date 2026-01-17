# Tasks for Fixing File Compress OOM Issue

## Phase 1: Streaming Compression

### Task 1.1: Modify `compress()` function to handle true streaming from stdin
- Remove temporary file buffering for stdin input
- Modify size calculation for streaming input
- Ensure progress tracking works with streaming

### Task 1.2: Modify `main()` function for streaming output
- Remove output temporary file buffering when writing to stdout
- Allow direct streaming from compression to output

## Phase 2: Memory Limits

### Task 2.1: Add memory limit option to command-line arguments
- New `--memory` or `--memlimit` option
- Accept human-readable sizes (K, M, G suffixes)

### Task 2.2: Implement memory limit support for compression tools
- zstd: Add `--memory=SIZE` option
- xz: Add `--memory=SIZE` option
- Handle tools without memory limit support gracefully

## Phase 3: Integrity Verification

### Task 3.1: Add checksum generation during compression
- SHA-256 checksum calculation
- Store checksum in file metadata or separate file

### Task 3.2: Add verification option
- New `--verify` option to verify compressed file integrity
- Compare checksum during decompression or verification

### Task 3.3: Update documentation and examples
- Add usage information for verification
- Examples of using compression with verification

## Phase 4: Testing and Validation

### Task 4.1: Test with small files
- Verify existing functionality remains intact
- Test all compression formats

### Task 4.2: Test with large files
- Test with files >10GB to verify OOM issue is fixed
- Monitor memory usage during compression

### Task 4.3: Test edge cases
- Empty files
- Very small files
- Binary files
- Different compression levels and threads

### Task 4.4: Performance benchmarking
- Compare memory usage before/after fix
- Measure compression speed changes
