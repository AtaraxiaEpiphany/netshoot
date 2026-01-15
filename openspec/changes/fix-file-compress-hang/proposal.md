# Fix File Compress Script Hanging Issue

## Problem Statement
The `file_compress` script was experiencing a hanging issue where the compression process would start but then hang indefinitely. This occurred because the compression commands (gzip, bzip2, xz, zstd) were missing the `-` argument, which tells them to read from stdin and write to stdout. Without this argument, the commands were waiting for input from the terminal instead of the piped input, causing the script to hang.

## Root Cause Analysis
The issue was identified in the `compress()` function where compression commands were called without the `-` argument:
- `gzip -$level` instead of `gzip -$level -`
- `bzip2 -$level` instead of `bzip2 -$level -`
- `xz -$level` instead of `xz -$level -`
- `zstd $zstd_opts --threads=$threads` instead of `zstd $zstd_opts --threads=$threads -`

This caused the compression tools to wait for terminal input rather than reading from the piped stdin.

## Solution Approach
Add the `-` argument to all compression commands in the `compress()` function to ensure they properly read from stdin and write to stdout when used in a pipeline context.

## Change Impact
- **Risk Level**: Low (simple argument addition)
- **Scope**: Single file modification in `file_compress` script
- **Testing**: Requires testing with various input sources (stdin, files) and compression formats
- **Backward Compatibility**: No breaking changes, only fixes existing functionality

## Success Criteria
- Script no longer hangs when compressing from stdin
- All compression formats work correctly with both file and stdin inputs
- Progress tracking and verbose modes continue to function properly
- Dry run mode remains unaffected