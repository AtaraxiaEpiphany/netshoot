# Change: Add Progress Bar to file_split Script

## Why
The `file_split` script currently splits files without providing any visual feedback on the progress. For large files, this can make it difficult to determine if the operation is still running or has completed. Adding a progress bar using the `pv` (pipe viewer) tool will improve the user experience by providing real-time progress updates.

## What Changes
- Add progress bar functionality to the `file_split` script using `pv` (pipe viewer)
- Ensure the progress bar is displayed when `pv` is available
- Maintain compatibility with existing functionality (checksum verification, dry run mode, etc.)
- Add `pv` to the list of dependencies in the documentation

## Impact
- Affected specs: file-split (new capability)
- Affected code: `/home/docker/workspace/git/netshoot/file_split`
- Affected documentation: `/home/docker/workspace/git/netshoot/openspec/project.md`
