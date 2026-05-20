# Change Proposal: Support Combined Short Options in file_split

## Problem Statement
Currently, the `file_split` utility requires each short option to be specified separately (e.g., `-v -o`). This violates common Unix CLI conventions where users expect to be able to combine single-letter options (e.g., `-vo` as a shorthand for `-v -o`). This limitation reduces usability and efficiency for advanced users.

## Proposed Solution
Modify the option parsing logic in `file_split` to support combining multiple short options after a single dash character.

### Specification
- **Combined Options Format**:
  ```
  file_split -vd split largefile.dat 10M
  ```
  Should be equivalent to:
  ```
  file_split -v -d split largefile.dat 10M
  ```

- **Implementation Approach**:
  1. Modify the option parsing loop to handle combined short options
  2. Preserve existing long option support (--verbose, --output)
  3. Maintain backward compatibility with existing usage patterns

### Behavior Changes
| Current Behavior | New Behavior |
|------------------|--------------|
| `file_split -v -d split file.dat 10M` | Still works |
| `file_split -vd split file.dat 10M` | Now equivalent to `-v -d` |
| `file_split -o /tmp -p part_ split file.dat 10M` | Still works |
| `file_split -o/tmp -ppart_ split file.dat 10M` | Still works (argument bundling remains unchanged) |
| `file_split -vo /tmp split file.dat 10M` | Now equivalent to `-v -o /tmp` |

## Implementation Plan
1. **Core Modifications**:
   - Revise option parsing logic in `file_split` (line ~396)
   - Add option combination splitting functionality before argument parsing
   - Preserve existing option validation rules

2. **Tests**:
   - Add test cases covering:
     - All valid combinations (`-vd`, `-vo`, `-vf`, `-vfd`, etc)
     - Invalid combinations (`-x` where x is undefined)
     - Boundary cases (`---`, `- `)
     - Combined options with arguments (`-vo /tmp`)
   - Verify behavior matches separated options

3. **Documentation Updates**:
   - Update help text (`-h/--help`) to document combined options support
   - Add examples showing combined options usage

## Impact Analysis
- **Positive**: Improved usability, aligns with CLI conventions, consistent with other utilities in the project
- **Risks**: Minimal - existing scripts using separated options remain unaffected
- **Backward Compatibility**: Fully maintained
- **Dependencies**: No new dependencies required

## Example Usage
```bash
# Split with verbose and dry run (new combined format)
file_split -vd split largefile.dat 10M

# Split with verbose, force directory creation, and custom output (combined format)
file_split -vfo /tmp/newdir split largefile.dat 100M

# Verify with verbose output (combined format)
file_split -v verify /tmp/newdir
```