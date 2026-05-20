# Fix Parallel Compression numfmt Command Bug

## Problem Statement
The `file_compress` script's parallel compression feature has a bug in the compression ratio calculation. When using the `-v` (verbose) flag, the script fails to display the input and output sizes correctly when using parallel chunk compression.

## Root Cause Analysis
The issue is in the compression ratio calculation section of the `main()` function at lines 596-597. The `numfmt` command is being called with quoted arguments that cause it to fail:

```bash
verbose "  Input Size:  $(numfmt --to=iec-i --suffix=B --format=\"%.1f\" \"$input_size\")"
verbose "  Output Size: $(numfmt --to=iec-i --suffix=B --format=\"%.1f\" \"$output_size\")"
```

The double quotes around the format string and variables cause the `numfmt` command to receive quoted arguments, resulting in errors like:
```
numfmt: invalid number: '"10485760"'
```

## Solution Approach
Fix the `numfmt` command calls by removing the unnecessary double quotes around the format string and variables:

```bash
verbose "  Input Size:  $(numfmt --to=iec-i --suffix=B --format=%.1f $input_size)"
verbose "  Output Size: $(numfmt --to=iec-i --suffix=B --format=%.1f $output_size)"
```

## Changes Required
1. Modify lines 596-597 in the `main()` function of the `file_compress` script
2. Remove double quotes around `numfmt` command arguments
3. Test the fix to ensure compression ratio calculation works correctly

## Change Impact
- **Risk Level**: Low (simple change to a single calculation)
- **Scope**: Single file modification in `file_compress` script
- **Testing**: Requires testing with various file sizes and chunk sizes
- **Backward Compatibility**: No breaking changes - existing functionality remains intact

## Success Criteria
1. Verbose output correctly displays input and output sizes
2. numfmt command no longer produces "invalid number" errors
3. Compression ratio calculation is accurate
4. Parallel chunk compression continues to work correctly

## Reproduction Steps
To reproduce the issue:
1. Create a test file
2. Run compression with verbose flag and chunking enabled:
   ```bash
   temp_file=$(mktemp) && dd if=/dev/urandom of="$temp_file" bs=1M count=10 2>/dev/null && ./file_compress -vo /tmp/test_output.zst -m 500MiB -s 1G "$temp_file"
   ```

## Verification Steps
1. Run the same command after applying the fix
2. Check that input and output sizes are correctly formatted

