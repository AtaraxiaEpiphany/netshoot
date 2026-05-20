# Change: Add Progress Bar to file_compress Script

## Why
The `file_compress` script currently has progress tracking capabilities using the `pv` (pipe viewer) tool, but the progress bar implementation has some issues. The progress tracking is not consistently applied in all compression scenarios, and the user experience could be improved by ensuring the progress bar is properly displayed when `pv` is available.

## What Changes
- Fix the progress bar implementation in the `file_compress` script
- Ensure the progress bar is consistently displayed for all compression formats when `pv` is available
- Improve the progress tracking logic to handle both file inputs and standard input correctly
- Verify the progress bar functionality works with the existing compression options (zstd, gzip, bzip2, xz)

## Impact
- Affected specs: file-compress (new capability)
- Affected code: `/home/docker/workspace/git/netshoot/file_compress`
