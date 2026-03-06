# OpenSpec Change Proposal: Add Parallel Chunk Compression to file_compress

## Problem Statement
The current file_compress script processes files as a single stream, which presents several limitations:
1. Very large files (>10GB) can still cause OOM issues despite streaming improvements
2. Compression cannot leverage multiple CPU cores effectively
3. Progress tracking lacks granularity for very large files
4. Interrupted compressions require restarting from beginning

## Proposed Solution
Implement parallel chunk compression with these key features:
1. **Intelligent Chunk Splitting**
   - Add `--chunk-size` option to specify chunk size (default: 1G)
   - Use GNU `split` command to divide input files into manageable chunks
   - Store temporary chunks in a unique `/tmp` directory

2. **Parallel Compression Engine**
   - Leverage GNU Parallel to compress chunks concurrently
   - Utilize zstd primarily due to its native concatenation support
   - Maintain existing flags (-l, -j, -m) for consistency

3. **Concatenation & Cleanup**
   - For zstd: Use `zstd --concatenate` to combine compressed chunks
   - For other formats: Use `cat` followed by format-specific validation
   - Implement robust cleanup process for temporary files

4. **Enhanced Progress Tracking**
   - Extend progress system to show:
     - Chunks completed/total
     - Overall progress percentage
     - Individual chunk compression rates

5. **Fault Tolerance**
   - Resume interrupted jobs by checking existing chunk files
   - Clean up partial work on SIGINT

## Implementation Plan

### Core Changes
1. **Argument Parsing** (lines 232-332)
   - Add new option: `--chunk-size SIZE`
   - Support human-readable sizes (1G, 500M)
   - Default: 0 (disable chunking)

2. **Chunk Preparation**
```bash
if [[ $CHUNK_SIZE -gt 0 && "$INPUT_FILE" != "-" ]]; then
  total_size=$(stat -c %s "$INPUT_FILE")
  if [[ $total_size -gt $CHUNK_SIZE ]]; then
    # Create temp directory
    tmp_dir=$(mktemp -d)

    # Split file
    split -b $CHUNK_SIZE "$INPUT_FILE" "$tmp_dir/chunk_"

    # Get chunk count
    chunk_count=$(ls "$tmp_dir" | wc -l)
  fi
fi
```

3. **Parallel Compression Engine**
```bash
compress_chunks() {
  find "$tmp_dir" -name "chunk_*" | parallel -j $THREADS \
    "file_compress --compression $COMPRESSION --level $COMPRESSION_LEVEL \
     --threads 1 --memlimit $MEMLIMIT -o {}.$ext {}"
}
```

4. **Chunk Concatenation**
```bash
# Zstd native concatenation
if [[ "$COMPRESSION" == "zstd" ]]; then
  zstd --concatenate -o "$OUTPUT_FILE" "$tmp_dir"/*.$ext
else
  cat "$tmp_dir"/*.$ext > "$OUTPUT_FILE"
fi
```

5. **Enhanced Progress Tracking**
- Add new function: `aggregate_progress()`
- Track:
  - $chunks_processed / $chunk_count
  - Overall MB processed
  - Estimated time remaining

## Risks and Mitigations
1. **Temporary Storage Requirements**
   - Risk: 2.5x disk space during compression (input + chunks + compressed chunks)
   - Mitigation: Warn users when free space < 3x input size
   - Mitigation: Add `--tmp-dir` option for custom temp location

2. **Format Compatibility**
   - Risk: Not all formats support clean concatenation
   - Solution: Only enable chunking for zstd by default
   - Solution: For other formats, validate output with format-specific checks

3. **Edge Case Handling**
   - Small files: Skip chunking if size < chunk size
   - Interruptions: Implement SIGINT handler for cleanup
   - Permissions: Verify temp directory has execute permissions

## Verification Plan
1. **Functional Testing**
   - Files smaller than chunk size (verify no chunking)
   - Files exactly matching chunk size
   - Files requiring multiple chunks
   - Mixed input sources (file vs stdin)
   - All supported compression formats

2. **Performance Benchmarking**
   - Compare compression times:
     | File Size | Chunk Size | Threads | Time |
     |---|---|---|---|
     | 20G | 0 | 8 | baseline |
     | 20G | 1G | 8 | target |
     | 20G | 2G | 16 | best case |
   - Measure peak memory usage

3. **Corner Case Validation**
   - Insufficient disk space handling
   - Insufficient file permissions
   - SIGINT during compression
   - Hardware resource exhaustion

4. **Comparative Validation**
   - Verify output matches non-chunked compression:
   ```bash
   diff <(file_compress -c zstd input) <(file_compress --chunk-size 1G -c zstd input)
   ```

## Documentation Updates
1. Update `--help` output
```
  --chunk-size SIZE     Split large files into chunks (default: disabled)
                        Supports size suffixes: K, M, G
                        Note: Recommended for files >10GB
```

2. Update man page with examples
```
EXAMPLES
  # Compress 50GB file using 1GB chunks
  file_compress --chunk-size 1G -o huge.zst hugefile

  # Compress with 1GB chunks and 16 threads
  file_compress --chunk-size 1G --threads 16 bigfile.tar
```

## Alternatives Considered
1. **Native Parallel Streams**
   - Approach: Use format-specific parallel compression
   - Limitation: Only zstd supports this well
   - Limitation: Other formats lack consistent implementation

2. **Custom Block Processing**
   - Approach: Handle chunking internally without temp files
   - Limitation: Greatly increases script complexity
   - Limitation: Hard to implement proper cleanup/resumption
