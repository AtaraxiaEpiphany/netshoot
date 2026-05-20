# Change: Add Progress Tracking for Zstd Compression Process

## Why
The `file_compress` script currently uses `pv` (pipe viewer) to show progress while reading input files, but there's a significant limitation with zstd compression: after `pv` finishes passing the file content to zstd, there's often a long wait time with no output while zstd completes the compression process. Users currently have to manually check if compression is still running using commands like `du -BM output.zst`.

This change addresses the usability issue by leveraging zstd's built-in `--progress` option to provide continuous feedback during the entire compression process.

## What Changes
- Modify the zstd compression logic in `/home/docker/workspace/git/netshoot/file_compress` to add progress tracking
- Add the `--progress` option to the zstd command in the `perform_compression()` function
- Ensure the progress tracking works correctly with both the pv pipe viewer and zstd's built-in progress
- Test the implementation to ensure it doesn't affect other compression formats

## How It Works
Zstd provides a built-in `--progress` option that displays real-time compression progress. This includes:
- Amount compressed
- Compression speed
- Estimated time remaining
- Compression ratio

This complements the existing pv progress bar, providing continuous feedback from the start of reading the file through the entire compression process.

## Impact
- Affected specs: file-compress (enhancement)
- Affected code: `/home/docker/workspace/git/netshoot/file_compress` (lines 117-131)
- Risk Level: Low (simple option addition)
- Testing: Requires testing with zstd compression at various levels to ensure progress tracking works correctly
- Backward Compatibility: No breaking changes, only enhances existing functionality

## Success Criteria
- Zstd compression shows continuous progress from start to finish
- Progress tracking works with both file inputs and stdin
- The implementation doesn't affect other compression formats (gzip, bzip2, xz)
- Compression still works correctly with all existing options (levels, threads, etc.)
- No performance degradation is introduced
