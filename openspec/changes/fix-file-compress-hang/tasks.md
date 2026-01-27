# Tasks: Fix File Compress Script Hanging Issue

## Implementation Tasks

1. **Modify compression commands in file_compress script**
   - Update gzip command: `gzip -$level` → `gzip -$level -`
   - Update bzip2 command: `bzip2 -$level` → `bzip2 -$level -`
   - Update xz command: `xz -$level` → `xz -$level -`
   - Update zstd command: `zstd $zstd_opts --threads=$threads` → `zstd $zstd_opts --threads=$threads -`

2. **Test the fix with various input scenarios**
   - Test with stdin input: `echo "test" | ./file_compress`
   - Test with file input: `./file_compress test.txt`
   - Test all compression formats: zstd, gzip, bzip2, xz
   - Test with verbose mode enabled
   - Test with progress tracking (if pv is available)

3. **Validate dry run mode functionality**
   - Ensure dry run mode still works correctly
   - Verify compression estimates are calculated properly

4. **Verify error handling**
   - Test with invalid input files
   - Verify error messages are still displayed correctly
   - Confirm script exits with appropriate error codes

## Validation Tasks

5. **Test edge cases**
   - Large file compression
   - Empty file compression
   - Binary file compression
   - Multiple compression levels

6. **Integration testing**
   - Test as part of pipeline: `cat file.txt | ./file_compress | ./file_compress -d`
   - Verify compatibility with file_split script interactions

7. **Documentation update**
   - Update script comments if necessary
   - Ensure usage examples remain accurate

## Dependencies
- No external dependencies required
- All testing can be done with existing tools in the netshoot environment

## Success Verification
- Script completes compression without hanging
- All compression formats work correctly
- No regression in existing functionality
- Error handling remains intact