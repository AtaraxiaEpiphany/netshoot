# Change Proposal: Support Combined Short Options in file_compress

## Problem Statement
Currently, the `file_compress` utility requires each short option to be specified separately (e.g., `-v -o`). This violates common Unix CLI conventions where users expect to be able to combine single-letter options (e.g., `-vo` as a shorthand for `-v -o`). This limitation reduces usability and efficiency for advanced users.

## Proposed Solution
Modify the option parsing logic in `file_compress` to support combining multiple short options after a single dash character.

### Specification
- **Combined Options Format**:
  ```
  file_compress -vo input.txt
  ```
  Should be equivalent to:
  ```
  file_compress -v -o input.txt
  ```

- **Implementation Approach**:
  1. Modify the option parsing loop to handle combined short options
  2. Preserve existing long option support (--verbose, --output)
  3. Maintain backward compatibility with existing usage patterns

### Behavior Changes
| Current Behavior | New Behavior |
|------------------|--------------|
| `file_compress -v -o out.txt` | Still works |
| `file_compress -vo out.txt` | Now equivalent to `-v -o` |
| `file_compress -z9 -v` | Still works |
| `file_compress -z9v` | Now equivalent to `-z9 -v` |

## Implementation Plan
1. **Core Modifications**:
   - Revise option parsing logic in `file_compress` (line ~200)
   - Add option combination splitting functionality
   - Preserve existing option validation rules

2. **Tests**:
   - Add test cases covering:
     - All valid combinations (`-vo`, `-zv`, `-z9v`, etc)
     - Invalid combinations (`-x` where x is undefined)
     - Boundary cases (`---`, `- `)
   - Verify behavior matches separated options

3. **Documentation Updates**:
   - Update help text (`-h/--help`)
   - Add examples to man page
   - Mention in README if appropriate

## Impact Analysis
- **Positive**: Improved usability, aligns with CLI conventions
- **Risks**: Minimal - existing scripts using separated options remain unaffected
- **Backward Compatibility**: Fully maintained

## Alternatives Considered
1. **Leave as-is**: Rejected - violates principle of least astonishment
2. **Implement getopt**: Rejected - would require more extensive changes and dependencies
3. **Only support common combinations**: Rejected - not flexible enough

## Unresolved Questions
- Should we support combining options with arguments? (e.g., `-oout.txt`)
  - Proposed: No, maintain explicit separation between options and arguments

## Timeline
- Implementation: 1 day
- Testing: 1 day
- Documentation: 0.5 day