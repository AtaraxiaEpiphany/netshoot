# File Split Specification

## MODIFIED Requirements

### Requirement: PROG-01: Progress Tracking during Splitting
- **Description**: The file_split script SHALL provide progress tracking during both file splitting and checksum verification operations when the `pv` tool is available.
- **Constraints**: MUST maintain existing functionality when pv is not available.
- **Acceptance Criteria**:
  - Progress bar SHALL be displayed during splitting when pv is available
  - Progress bar SHALL be displayed during reassembled checksum verification when pv is available
  - Operation SHALL continue normally without progress bar when pv is unavailable
  - A warning SHALL be logged when pv is not available

#### Scenario: Splitting with pv available
Given pv is installed on the system
When I run `file_split split [FILE] [SIZE]`
Then I should see a progress bar during the splitting operation

#### Scenario: Splitting without pv
Given pv is not installed on the system
When I run `file_split split [FILE] [SIZE]`
Then the operation should complete without a progress bar
And I should see a warning message about pv not being available

## ADDED Requirements

### Requirement: DEP-01: Optional pv Dependency
- **Description**: pv SHALL be treated as an optional dependency for file_split
- **Acceptance Criteria**:
  - Script SHALL check for pv availability during initialization
  - Script SHALL function normally whether pv is present or not

#### Scenario: Script initialization with pv
Given pv is installed on the system
When I run `file_split --help`
Then the script should initialize without errors

#### Scenario: Script initialization without pv
Given pv is not installed on the system
When I run `file_split --help`
Then the script should initialize without errors
And I should see no warnings about missing dependencies
