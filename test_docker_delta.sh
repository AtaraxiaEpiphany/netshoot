#!/usr/bin/env bash
set -euo pipefail

# Test script for docker_delta utility

echo "=== Docker Delta Test Script ==="
echo "Testing docker_delta version $(./docker_delta --version)"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_exit=${3:-0}

    echo -n "Testing $test_name..."

    if eval "$command" &>/dev/null; then
        echo -e "${GREEN} ✓${NC}"
        return 0
    else
        local exit_code=$?
        if [[ $exit_code -eq $expected_exit ]]; then
            echo -e "${YELLOW} - (expected failure)${NC}"
            return 0
        fi
        echo -e "${RED} ✗${NC} (exit code: $exit_code)"
        return 1
    fi
}

# Test 1: Check if docker_delta is executable
echo "1. Basic script functionality:"
run_test "Script execution" "./docker_delta --help"

# Test 2: Check version output
run_test "Version output" "./docker_delta --version"

# Test 3: Check if file_delta is available
echo -e "\n2. File delta utility:"
run_test "File delta available" "file_delta --help"

# Test 4: Create delta from hello-world:latest
echo -e "\n3. Delta creation tests:"
DELTA_PACKAGE="test_hello_world.delta.tar.gz"
rm -f "$DELTA_PACKAGE"

if run_test "Create hello-world delta" "./docker_delta -d create hello-world:latest $DELTA_PACKAGE"; then
    echo "   Dry run successful"
else
    echo -e "   ${RED}Failed to create delta package${NC}"
fi

# Test 5: Check if we have multiple hello-world images
echo -e "\n4. Image comparison tests:"
if docker images | grep -q "hello-world:linux"; then
    run_test "Delta between hello-world versions (dry run)" "./docker_delta -d create hello-world:latest hello-world:linux hello-world-update.delta.tar.gz"
fi

# Test 6: Verify script requirements
echo -e "\n5. Dependency checks:"
for cmd in "python3" "tar" "skopeo"; do
    if command -v "$cmd" >/dev/null; then
        echo -e "   ${GREEN}✓${NC} $cmd is available"
    else
        echo -e "   ${YELLOW}-${NC} $cmd is not available (optional)"
    fi
done

# Test 7: Create a test delta package (real test)
echo -e "\n6. Real delta creation test:"
echo "Creating delta package from hello-world:latest..."
if ./docker_delta create hello-world:latest $DELTA_PACKAGE; then
    echo -e "   ${GREEN}✓${NC} Delta package created"
    if [ -f "$DELTA_PACKAGE" ]; then
        PACKAGE_SIZE=$(du -h "$DELTA_PACKAGE" | cut -f1)
        echo -e "   Package size: $PACKAGE_SIZE"

        # Test 8: List delta package
        if run_test "List delta package layers" "./docker_delta list $DELTA_PACKAGE"; then
            echo "   Layer list successful"
        fi

        # Test 9: Show delta package info
        if run_test "Show delta package info" "./docker_delta info $DELTA_PACKAGE"; then
            echo "   Package info successful"
        fi
    fi
else
    echo -e "   ${RED}✗${NC} Failed to create delta package"
fi

# Test 10: Clean up
echo -e "\n7. Cleanup:"
if [ -f "$DELTA_PACKAGE" ]; then
    rm -f "$DELTA_PACKAGE"
    echo "   Delta package removed"
fi

if [ -f "hello-world-update.delta.tar.gz" ]; then
    rm -f "hello-world-update.delta.tar.gz"
fi

echo -e "\n=== Test completed ==="
