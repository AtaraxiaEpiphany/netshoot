# Refactor file_delta Script - Tasks

## Task List

1. **Extract Constants**
   - Add exit code constants (EXIT_SUCCESS, EXIT_ERROR, etc.)
   - Add supported methods and formats constants
   - Add compression level range constants
   - Replace magic numbers with constants throughout the script

2. **Add New Helper Functions**
   - Create `build_rsync_command()` function to eliminate duplication
   - Create `validate_compression_level()` for centralized validation
   - Create `detect_compression_format()` to extract compression detection

3. **Reorganize Functions by Concern**
   - Group logging functions (error, verbose)
   - Group utility functions (command_exists, get_path_type)
   - Group validation functions (validate_inputs, new validate_compression_level)
   - Group delta method functions (xdelta3, bsdiff, rsync)
   - Group compression functions (compress_delta, decompress_delta)
   - Group core operations (create_delta, apply_delta)
   - Group CLI interface (parse_args, usage, main)

4. **Eliminate Code Duplication**
   - Refactor `create_rsync_delta()` to use `build_rsync_command()`
   - Refactor `apply_rsync_delta()` to use `build_rsync_command()`
   - Remove duplicate rsync command building logic

5. **Improve Error Handling**
   - Update error() function to use exit code constants
   - Add specific error codes for different scenarios
   - Ensure all error calls use appropriate exit codes

6. **Add Section Comments**
   - Add descriptive comments for each function group
   - Add inline comments for complex logic

7. **Functional Testing**
   - Test xdelta3 delta creation and application
   - Test bsdiff delta creation and application
   - Test rsync delta creation and application
   - Test all compression formats (zstd, gzip, bzip2, xz, none)
   - Test all CLI options (-m, -c, -l, -v, -d, -f, -z)
   - Test combined short options (e.g., -vd)

8. **Regression Testing**
   - Verify all exit codes match original behavior
   - Verify all error messages match original behavior
   - Verify all output messages match original behavior
   - Test edge cases (empty files, large files, special characters)

9. **Code Quality Verification**
   - Verify no code duplication remains
   - Verify all constants are used consistently
   - Verify all functions are properly organized
   - Verify script still follows Netshoot conventions
