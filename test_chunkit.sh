#!/bin/bash

# Test script for chunkit compression utility

# Function to run tests
run_test() {
    local description="$1"
    local command="$2"
    local expected_status="${3:-0}"

    echo "TEST: $description"
    echo "COMMAND: $command"

    eval "$command"
    status=$?

    if [[ $status -eq $expected_status ]]; then
        echo -e "\033[0;32m[PASS]\033[0m"
    else
        echo -e "\033[0;31m[FAIL]\033[0m (status: $status)"
        exit 1
    fi
    echo ""
}

# Test 1: Basic stdin compression
run_test "Basic stdin compression" \
    "echo 'test data' | ./chunkit > test1.zst"

# Test 2: Different compression formats
formats=(zstd gzip bzip2 xz)
for format in "${formats[@]}"; do
    run_test "Compression with $format format" \
        "echo 'test data' | ./chunkit -c $format > test_${format}.compressed"
done

# Test 3: Specify output file
run_test "Specify output file" \
    "./chunkit -o test3.zst << EOF
Multiline
Test Data
EOF"

# Test 4: Verbose mode
run_test "Verbose mode" \
    "echo 'test data' | ./chunkit -v -o test4.zst"

# Test 5: Fast compression
run_test "Fast zstd compression" \
    "echo 'test data' | ./chunkit -c zstd -l -10 > test5.zst"

echo "All tests completed successfully!"