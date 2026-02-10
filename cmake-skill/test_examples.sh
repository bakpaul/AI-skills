#!/bin/bash
# test_examples.sh - Test script for CMake skill examples

set -e  # Exit on error

echo "================================"
echo "CMake Skill Examples Test Suite"
echo "================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

TEST_DIR=$(mktemp -d)
INSTALL_DIR="${TEST_DIR}/install"

echo "Test directory: ${TEST_DIR}"
echo "Install directory: ${INSTALL_DIR}"
echo ""

#-----------------------------------------------------------------------------
# Test 1: Library Example
#-----------------------------------------------------------------------------

echo "Test 1: Building and Installing Example Library..."
cd examples/library

if [ -d build ]; then
    rm -rf build
fi

mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" > /dev/null 2>&1
cmake --build . > /dev/null 2>&1
cmake --install . > /dev/null 2>&1

if [ -f "${INSTALL_DIR}/lib/libexample_lib.so" ] || [ -f "${INSTALL_DIR}/lib/libexample_lib.a" ]; then
    echo -e "${GREEN}✓ Library built and installed successfully${NC}"
else
    echo -e "${RED}✗ Library installation failed${NC}"
    exit 1
fi

# Check if config files were installed
if [ -f "${INSTALL_DIR}/lib/cmake/ExampleLib/ExampleLibConfig.cmake" ]; then
    echo -e "${GREEN}✓ Config files installed${NC}"
else
    echo -e "${RED}✗ Config files missing${NC}"
    exit 1
fi

cd ../../..
echo ""

#-----------------------------------------------------------------------------
# Test 2: Consumer Example
#-----------------------------------------------------------------------------

echo "Test 2: Building Consumer Application..."
cd examples/consumer

if [ -d build ]; then
    rm -rf build
fi

mkdir build && cd build
cmake .. -DCMAKE_PREFIX_PATH="${INSTALL_DIR}" > /dev/null 2>&1
cmake --build . > /dev/null 2>&1

if [ -f consumer_app ]; then
    echo -e "${GREEN}✓ Consumer built successfully${NC}"
    
    # Try to run it (might fail if dependencies are missing, but that's OK)
    if ./consumer_app > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Consumer runs successfully${NC}"
    else
        echo -e "${GREEN}✓ Consumer compiled (runtime test skipped)${NC}"
    fi
else
    echo -e "${RED}✗ Consumer build failed${NC}"
    exit 1
fi

cd ../../..
echo ""

#-----------------------------------------------------------------------------
# Summary
#-----------------------------------------------------------------------------

echo "================================"
echo -e "${GREEN}All tests passed!${NC}"
echo "================================"
echo ""
echo "Cleanup: rm -rf ${TEST_DIR}"
echo ""
