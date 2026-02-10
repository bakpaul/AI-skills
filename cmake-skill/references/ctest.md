# CTest - Testing with CMake

CTest is CMake's built-in testing tool for running and reporting test results.

## Table of Contents

1. [Overview](#overview)
2. [Basic Testing](#basic-testing)
3. [Adding Tests](#adding-tests)
4. [Running Tests](#running-tests)
5. [Test Properties](#test-properties)
6. [Advanced Testing](#advanced-testing)
7. [Integration with Test Frameworks](#integration-with-test-frameworks)
8. [CDash Integration](#cdash-integration)
9. [Best Practices](#best-practices)

## Overview

**What is CTest?**
CTest runs your tests, measures execution time, and reports results. It's part of CMake and works with any test framework.

**Workflow:**
```
cmake -S . -B build        # Configure
cmake --build build        # Build (including tests)
ctest --test-dir build     # Run tests
```

**Key features:**
- Parallel test execution
- Test filtering and selection
- Timeout handling
- Output capture
- Integration with CI/CD
- CDash reporting (optional)

## Basic Testing

### Enabling Testing

Add to your CMakeLists.txt:

```cmake
cmake_minimum_required(VERSION 3.15)
project(MyProject)

# Enable testing
enable_testing()

# Your targets
add_executable(myapp src/main.cpp)
add_executable(test_myapp tests/test_main.cpp)

# Add test
add_test(NAME MyTest COMMAND test_myapp)
```

### Minimal Example

```cmake
# CMakeLists.txt
cmake_minimum_required(VERSION 3.15)
project(Calculator)

enable_testing()

# Main library
add_library(calculator src/calculator.cpp)

# Test executable
add_executable(test_calculator tests/test_calculator.cpp)
target_link_libraries(test_calculator PRIVATE calculator)

# Add test
add_test(NAME CalculatorTest COMMAND test_calculator)
```

### Running Tests

```bash
# Configure and build
cmake -S . -B build
cmake --build build

# Run all tests
ctest --test-dir build

# Or from build directory
cd build
ctest
```

## Adding Tests

### Simple Command Test

```cmake
add_test(NAME TestName COMMAND executable arg1 arg2)
```

**Example:**
```cmake
add_executable(my_test tests/test.cpp)
add_test(NAME BasicTest COMMAND my_test)
```

### Test with Arguments

```cmake
add_test(NAME TestWithArgs 
    COMMAND my_test --input data.txt --verbose
)
```

### Test Script Execution

```cmake
# Run a CMake script
add_test(NAME ScriptTest 
    COMMAND ${CMAKE_COMMAND} -P ${CMAKE_SOURCE_DIR}/test_script.cmake
)

# Run a shell script
add_test(NAME ShellTest 
    COMMAND ${CMAKE_SOURCE_DIR}/test.sh
)
```

### Multiple Tests from One Executable

```cmake
add_executable(calculator_tests tests/test_all.cpp)

# Different test cases
add_test(NAME AdditionTest 
    COMMAND calculator_tests --test-case=addition
)

add_test(NAME SubtractionTest 
    COMMAND calculator_tests --test-case=subtraction
)

add_test(NAME MultiplicationTest 
    COMMAND calculator_tests --test-case=multiplication
)
```

### Working Directory

```cmake
add_test(NAME TestWithWorkDir
    COMMAND my_test
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/test_data
)
```

## Running Tests

### Basic Commands

```bash
# Run all tests
ctest

# Run with verbose output
ctest -V
ctest --verbose

# Run with extra verbose output (shows test output)
ctest -VV
ctest --extra-verbose

# Run specific test
ctest -R TestName
ctest --tests-regex TestName

# Exclude tests
ctest -E SlowTest
ctest --exclude-regex SlowTest
```

### Parallel Execution

```bash
# Run tests in parallel (8 jobs)
ctest -j8
ctest --parallel 8

# Use all CPU cores
ctest -j$(nproc)     # Linux
ctest -j$(sysctl -n hw.ncpu)  # macOS
```

### Test Selection

```bash
# Run tests matching pattern
ctest -R "^Unit"              # Tests starting with "Unit"
ctest -R "Math"               # Tests containing "Math"

# Run tests by label
ctest -L Fast                 # Only "Fast" labeled tests
ctest -LE Slow                # Exclude "Slow" labeled tests

# Run failed tests only
ctest --rerun-failed

# Run until first failure
ctest --stop-on-failure
```

### Test Output

```bash
# Show test output on failure
ctest --output-on-failure

# Show all output
ctest --verbose

# Capture output to file
ctest --output-log test_results.log

# Generate JUnit XML (for CI)
ctest --output-junit results.xml
```

### Advanced Options

```bash
# Set timeout for all tests
ctest --timeout 30

# Run tests in random order
ctest --schedule-random

# Repeat tests
ctest --repeat until-fail:3   # Repeat up to 3 times until failure
ctest --repeat until-pass:5   # Repeat up to 5 times until pass
ctest --repeat after-timeout:3  # Repeat if timeout

# Show only summary
ctest --quiet
```

## Test Properties

### Setting Test Properties

```cmake
add_test(NAME MyTest COMMAND test_executable)

# Set properties
set_tests_properties(MyTest PROPERTIES
    TIMEOUT 30                    # Test timeout in seconds
    WILL_FAIL TRUE               # Expect test to fail
    PASS_REGULAR_EXPRESSION "Success"
    FAIL_REGULAR_EXPRESSION "Error"
    LABELS "Unit;Fast"
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    ENVIRONMENT "VAR=value"
)
```

### Common Properties

#### Timeout

```cmake
# Test-specific timeout
set_tests_properties(SlowTest PROPERTIES TIMEOUT 300)

# Global timeout (in CTestConfig.cmake or command line)
set(CTEST_TEST_TIMEOUT 60)
```

#### Expected Failure

```cmake
# Test is expected to fail (failure = pass)
set_tests_properties(TestBugFix PROPERTIES WILL_FAIL TRUE)
```

#### Output Validation

```cmake
# Test passes if output contains regex
set_tests_properties(OutputTest PROPERTIES
    PASS_REGULAR_EXPRESSION "All tests passed"
)

# Test fails if output contains regex
set_tests_properties(ErrorTest PROPERTIES
    FAIL_REGULAR_EXPRESSION "ERROR|FATAL|CRASH"
)

# Must match both
set_tests_properties(ValidationTest PROPERTIES
    PASS_REGULAR_EXPRESSION "Success"
    FAIL_REGULAR_EXPRESSION "Error"
)
```

#### Labels

```cmake
# Organize tests by labels
set_tests_properties(UnitTest1 UnitTest2 PROPERTIES
    LABELS "Unit;Fast"
)

set_tests_properties(IntegrationTest1 PROPERTIES
    LABELS "Integration;Slow"
)

# Run by label: ctest -L Unit
```

#### Environment Variables

```cmake
# Set environment for test
set_tests_properties(MyTest PROPERTIES
    ENVIRONMENT "PATH=/custom/path:$ENV{PATH};DEBUG=1"
)
```

#### Dependencies

```cmake
# Test B runs only if Test A passes
set_tests_properties(TestB PROPERTIES
    DEPENDS TestA
)

# Multiple dependencies
set_tests_properties(TestC PROPERTIES
    DEPENDS "TestA;TestB"
)
```

#### Resource Locks

```cmake
# Tests that can't run in parallel (share resource)
set_tests_properties(DBTest1 DBTest2 PROPERTIES
    RESOURCE_LOCK database
)
```

#### Cost (Execution Order)

```cmake
# Run expensive tests first (higher cost = earlier execution)
set_tests_properties(SlowTest PROPERTIES COST 100)
set_tests_properties(FastTest PROPERTIES COST 1)
```

## Advanced Testing

### Fixtures (Setup/Cleanup)

Fixtures ensure setup runs before tests and cleanup after.

```cmake
# Setup fixture
add_test(NAME SetupDB COMMAND setup_database)
set_tests_properties(SetupDB PROPERTIES
    FIXTURES_SETUP Database
)

# Tests requiring fixture
add_test(NAME DBTest1 COMMAND test_db_queries)
add_test(NAME DBTest2 COMMAND test_db_inserts)
set_tests_properties(DBTest1 DBTest2 PROPERTIES
    FIXTURES_REQUIRED Database
)

# Cleanup fixture
add_test(NAME CleanupDB COMMAND cleanup_database)
set_tests_properties(CleanupDB PROPERTIES
    FIXTURES_CLEANUP Database
)
```

**CTest automatically runs:** SetupDB → DBTest1, DBTest2 → CleanupDB

### Parameterized Tests

```cmake
# Function to add multiple test cases
function(add_calculator_test operation a b expected)
    add_test(
        NAME "Calculator_${operation}_${a}_${b}"
        COMMAND calculator_test ${operation} ${a} ${b} ${expected}
    )
endfunction()

# Add multiple test cases
add_calculator_test(add 2 3 5)
add_calculator_test(add 10 20 30)
add_calculator_test(subtract 10 3 7)
add_calculator_test(multiply 4 5 20)
```

### Custom Test Commands

```cmake
# Compare file output
add_test(NAME CompareOutput
    COMMAND ${CMAKE_COMMAND} -E compare_files
        ${CMAKE_BINARY_DIR}/output.txt
        ${CMAKE_SOURCE_DIR}/expected.txt
)

# Check file exists
add_test(NAME CheckFile
    COMMAND ${CMAKE_COMMAND} -E cat
        ${CMAKE_BINARY_DIR}/required_file.txt
)
```

### CTest Scripts

For complex test scenarios, create a CTest script:

```cmake
# MyCTest.cmake
set(CTEST_SOURCE_DIRECTORY "${CMAKE_SOURCE_DIR}")
set(CTEST_BINARY_DIRECTORY "${CMAKE_BINARY_DIR}")

# Configure
ctest_configure()

# Build
ctest_build()

# Test
ctest_test()

# Coverage (if enabled)
ctest_coverage()

# Submit to CDash (optional)
# ctest_submit()
```

Run with:
```bash
ctest -S MyCTest.cmake
```

## Integration with Test Frameworks

### Google Test

```cmake
# Find or fetch Google Test
find_package(GTest QUIET)
if(NOT GTest_FOUND)
    include(FetchContent)
    FetchContent_Declare(
        googletest
        GIT_REPOSITORY https://github.com/google/googletest.git
        GIT_TAG v1.14.0
    )
    FetchContent_MakeAvailable(googletest)
endif()

enable_testing()

# Test executable
add_executable(my_tests tests/test_main.cpp)
target_link_libraries(my_tests PRIVATE GTest::gtest_main)

# Auto-discover tests
include(GoogleTest)
gtest_discover_tests(my_tests)
```

**`gtest_discover_tests()`** automatically creates CTest entries for each Google Test case.

### Catch2

```cmake
find_package(Catch2 3 QUIET)
if(NOT Catch2_FOUND)
    include(FetchContent)
    FetchContent_Declare(
        Catch2
        GIT_REPOSITORY https://github.com/catchorg/Catch2.git
        GIT_TAG v3.5.0
    )
    FetchContent_MakeAvailable(Catch2)
endif()

enable_testing()

add_executable(tests tests/test_main.cpp)
target_link_libraries(tests PRIVATE Catch2::Catch2WithMain)

# Auto-discover tests
include(Catch)
catch_discover_tests(tests)
```

### doctest

```cmake
find_package(doctest QUIET)
if(NOT doctest_FOUND)
    include(FetchContent)
    FetchContent_Declare(
        doctest
        GIT_REPOSITORY https://github.com/doctest/doctest.git
        GIT_TAG v2.4.11
    )
    FetchContent_MakeAvailable(doctest)
endif()

enable_testing()

add_executable(tests tests/test_main.cpp)
target_link_libraries(tests PRIVATE doctest::doctest)

# Add test
add_test(NAME DoctestSuite COMMAND tests)
```

### Custom Test Framework

```cmake
# Simple assertion-based tests
add_executable(my_test tests/simple_test.cpp)

# Test returns 0 on success, non-zero on failure
add_test(NAME SimpleTest COMMAND my_test)
```

**Example test (simple_test.cpp):**
```cpp
#include <cassert>

void test_addition() {
    assert(2 + 2 == 4);
}

int main() {
    test_addition();
    return 0;  // Success
}
```

## CDash Integration

CDash provides web-based test result dashboard.

### Basic CDash Setup

```cmake
# CTestConfig.cmake in project root
set(CTEST_PROJECT_NAME "MyProject")
set(CTEST_NIGHTLY_START_TIME "00:00:00 UTC")

set(CTEST_DROP_METHOD "http")
set(CTEST_DROP_SITE "my.cdash.org")
set(CTEST_DROP_LOCATION "/submit.php?project=MyProject")
set(CTEST_DROP_SITE_CDASH TRUE)
```

### Submitting Results

```bash
# Configure with build name
cmake -S . -B build -DBUILDNAME="Ubuntu-GCC"

# Build and test
cd build
cmake --build .

# Submit to CDash
ctest -D Experimental    # Experimental build
# Or
ctest -D Nightly        # Nightly build
# Or
ctest -D Continuous     # Continuous build
```

### Coverage Reports

```cmake
# CMakeLists.txt
option(CODE_COVERAGE "Enable coverage reporting" OFF)

if(CODE_COVERAGE)
    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        target_compile_options(mylib PRIVATE --coverage)
        target_link_options(mylib PRIVATE --coverage)
    endif()
endif()
```

```bash
# Build with coverage
cmake -S . -B build -DCODE_COVERAGE=ON
cmake --build build

# Run tests
cd build
ctest

# Generate coverage report
ctest -D ExperimentalCoverage

# Or use external tools
gcov -r -b *.gcno
lcov --capture --directory . --output-file coverage.info
genhtml coverage.info --output-directory coverage_html
```

## Best Practices

### 1. Organize Tests by Labels

```cmake
# Unit tests - fast, no dependencies
set_tests_properties(UnitTests PROPERTIES LABELS "Unit;Fast")

# Integration tests - slower, may need setup
set_tests_properties(IntegrationTests PROPERTIES LABELS "Integration;Slow")

# System tests - full system, very slow
set_tests_properties(SystemTests PROPERTIES LABELS "System;Slow")

# Run: ctest -L Unit  (fast feedback)
# Run: ctest -L "Unit|Integration"  (more complete)
```

### 2. Set Appropriate Timeouts

```cmake
# Fast unit tests
set_tests_properties(UnitTests PROPERTIES TIMEOUT 5)

# Integration tests
set_tests_properties(IntegrationTests PROPERTIES TIMEOUT 30)

# End-to-end tests
set_tests_properties(E2ETests PROPERTIES TIMEOUT 300)
```

### 3. Use Fixtures for Expensive Setup

```cmake
# Setup once
add_test(NAME SetupTestEnv COMMAND create_test_env)
set_tests_properties(SetupTestEnv PROPERTIES FIXTURES_SETUP TestEnv)

# All tests use the fixture
set_tests_properties(Test1 Test2 Test3 PROPERTIES
    FIXTURES_REQUIRED TestEnv
)

# Cleanup once
add_test(NAME CleanupTestEnv COMMAND destroy_test_env)
set_tests_properties(CleanupTestEnv PROPERTIES FIXTURES_CLEANUP TestEnv)
```

### 4. Validate Test Output

```cmake
# Ensure test produces expected output
set_tests_properties(ValidationTest PROPERTIES
    PASS_REGULAR_EXPRESSION "All checks passed"
    FAIL_REGULAR_EXPRESSION "FATAL|ERROR|CRASH"
)
```

### 5. Separate Test Build Option

```cmake
# Only build tests if testing is enabled
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    option(BUILD_TESTING "Build tests" ON)
else()
    option(BUILD_TESTING "Build tests" OFF)
endif()

if(BUILD_TESTING)
    enable_testing()
    add_subdirectory(tests)
endif()
```

### 6. Use Resource Locks for Shared Resources

```cmake
# Tests that access same database
set_tests_properties(DBTest1 DBTest2 DBTest3 PROPERTIES
    RESOURCE_LOCK database
)

# Tests that write to same file
set_tests_properties(FileTest1 FileTest2 PROPERTIES
    RESOURCE_LOCK testfile
)
```

### 7. Exclude Tests from ALL Target

```cmake
# Don't build tests by default
add_executable(my_test tests/test.cpp)
set_target_properties(my_test PROPERTIES
    EXCLUDE_FROM_ALL TRUE
)

# Build tests explicitly
# cmake --build build --target my_test
# Or build when testing: ctest --build-and-test
```

### 8. Test Installation

```cmake
# Test that installed files work
install(TARGETS myapp DESTINATION bin)

# Installation test (run after install)
add_test(NAME InstallTest
    COMMAND ${CMAKE_INSTALL_PREFIX}/bin/myapp --version
)
```

### 9. Cross-Platform Tests

```cmake
# Platform-specific tests
if(WIN32)
    add_test(NAME WindowsTest COMMAND windows_specific_test)
elseif(UNIX)
    add_test(NAME UnixTest COMMAND unix_specific_test)
endif()

# Or use properties
add_test(NAME WindowsOnly COMMAND test.exe)
if(NOT WIN32)
    set_tests_properties(WindowsOnly PROPERTIES DISABLED TRUE)
endif()
```

### 10. Continuous Integration

```cmake
# CTest script for CI (ci_test.cmake)
set(CTEST_SOURCE_DIRECTORY "${CMAKE_SOURCE_DIR}")
set(CTEST_BINARY_DIRECTORY "${CMAKE_SOURCE_DIR}/build")

# Configure
ctest_configure()

# Build
ctest_build(NUMBER_ERRORS build_errors)

# Only test if build succeeded
if(build_errors EQUAL 0)
    # Test with verbose output on failure
    ctest_test(RETURN_VALUE test_result)
    
    # Generate coverage if enabled
    if(CODE_COVERAGE)
        ctest_coverage()
    endif()
endif()
```

## Common Patterns

### Pattern 1: Simple Project with Tests

```cmake
cmake_minimum_required(VERSION 3.15)
project(MyApp VERSION 1.0)

# Main executable
add_executable(myapp src/main.cpp src/utils.cpp)

# Enable testing
enable_testing()

# Test executable
add_executable(test_utils tests/test_utils.cpp src/utils.cpp)

# Add tests
add_test(NAME UtilsTest COMMAND test_utils)
set_tests_properties(UtilsTest PROPERTIES
    TIMEOUT 10
    LABELS "Unit"
)
```

### Pattern 2: Library with Unit Tests

```cmake
# Library
add_library(mylib src/mylib.cpp)

# Tests
enable_testing()

add_executable(test_mylib tests/test_mylib.cpp)
target_link_libraries(test_mylib PRIVATE mylib)

add_test(NAME MyLibTests COMMAND test_mylib)
```

### Pattern 3: Multiple Test Suites

```cmake
enable_testing()

# Unit tests
add_executable(unit_tests tests/unit/*.cpp)
add_test(NAME UnitTests COMMAND unit_tests)
set_tests_properties(UnitTests PROPERTIES LABELS "Unit")

# Integration tests
add_executable(integration_tests tests/integration/*.cpp)
add_test(NAME IntegrationTests COMMAND integration_tests)
set_tests_properties(IntegrationTests PROPERTIES LABELS "Integration")

# Run fast tests only: ctest -L Unit
```

### Pattern 4: Test Fixture Pattern

```cmake
# Setup
add_test(NAME Setup COMMAND create_test_data)
set_tests_properties(Setup PROPERTIES FIXTURES_SETUP Data)

# Tests
add_test(NAME Test1 COMMAND test1)
add_test(NAME Test2 COMMAND test2)
set_tests_properties(Test1 Test2 PROPERTIES FIXTURES_REQUIRED Data)

# Cleanup
add_test(NAME Cleanup COMMAND remove_test_data)
set_tests_properties(Cleanup PROPERTIES FIXTURES_CLEANUP Data)
```

## Quick Reference

### Basic Commands

```bash
ctest                          # Run all tests
ctest -V                       # Verbose output
ctest -j8                      # Parallel (8 jobs)
ctest -R TestName              # Run specific test
ctest -L Label                 # Run tests with label
ctest --output-on-failure      # Show output for failures
ctest --rerun-failed           # Re-run failed tests
```

### CMake Functions

```cmake
enable_testing()                              # Enable testing support
add_test(NAME name COMMAND cmd args...)      # Add a test
set_tests_properties(tests PROPERTIES ...)   # Set test properties
```

### Common Properties

```cmake
TIMEOUT seconds               # Test timeout
WILL_FAIL TRUE               # Expected to fail
LABELS "Label1;Label2"       # Organize tests
DEPENDS "Test1;Test2"        # Test dependencies
FIXTURES_SETUP name          # Setup fixture
FIXTURES_REQUIRED name       # Require fixture
FIXTURES_CLEANUP name        # Cleanup fixture
RESOURCE_LOCK name           # Prevent parallel execution
WORKING_DIRECTORY path       # Working directory
ENVIRONMENT "VAR=value"      # Environment variables
```

### Test Selection

```bash
-R regex          # Run tests matching regex
-E regex          # Exclude tests matching regex
-L label          # Run tests with label
-LE label         # Exclude tests with label
-I [Start,End]    # Run tests by index range
```

## Troubleshooting

### Tests Not Found

**Check:**
1. Did you call `enable_testing()` in CMakeLists.txt?
2. Did you run CMake configure after adding tests?
3. Run `ctest -N` to list all tests

```bash
# List tests without running
ctest -N
```

### Tests Fail in CI But Pass Locally

**Common causes:**
- Missing environment variables
- Different working directory
- Resource conflicts (parallel execution)
- Timeout too short

**Solutions:**
```cmake
# Set working directory explicitly
set_tests_properties(MyTest PROPERTIES
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
)

# Prevent parallel execution
set_tests_properties(MyTest PROPERTIES
    RESOURCE_LOCK exclusive
)

# Increase timeout
set_tests_properties(MyTest PROPERTIES
    TIMEOUT 60
)
```

### Test Output Not Visible

```bash
# Show output on failure
ctest --output-on-failure

# Show all output
ctest -V

# Save output to file
ctest --output-log results.txt
```

### Test Hangs

**Solution:**
```cmake
# Add timeout
set_tests_properties(HangTest PROPERTIES TIMEOUT 30)
```

```bash
# Or set global timeout
ctest --timeout 60
```

### Parallel Tests Interfere

**Solution:**
```cmake
# Use resource locks
set_tests_properties(Test1 Test2 PROPERTIES
    RESOURCE_LOCK shared_resource
)
```

## Examples

### Complete Testing Setup

```cmake
cmake_minimum_required(VERSION 3.15)
project(Calculator VERSION 1.0)

# Library
add_library(calculator src/calculator.cpp)
target_include_directories(calculator PUBLIC include)

# Enable testing
enable_testing()

# Test executable
add_executable(calculator_tests tests/test_calculator.cpp)
target_link_libraries(calculator_tests PRIVATE calculator)

# Add tests
add_test(NAME AdditionTest 
    COMMAND calculator_tests addition
)

add_test(NAME SubtractionTest 
    COMMAND calculator_tests subtraction
)

# Set properties
set_tests_properties(AdditionTest SubtractionTest PROPERTIES
    TIMEOUT 5
    LABELS "Unit;Fast"
)
```

### Running Tests

```bash
# Build
cmake -S . -B build
cmake --build build

# Run all tests
ctest --test-dir build

# Run with output on failure
ctest --test-dir build --output-on-failure

# Run parallel
ctest --test-dir build -j8

# Run specific tests
ctest --test-dir build -R Addition
```

## References

- [CTest Documentation](https://cmake.org/cmake/help/latest/manual/ctest.1.html)
- [enable_testing()](https://cmake.org/cmake/help/latest/command/enable_testing.html)
- [add_test()](https://cmake.org/cmake/help/latest/command/add_test.html)
- [set_tests_properties()](https://cmake.org/cmake/help/latest/command/set_tests_properties.html)
- [CDash](https://www.cdash.org/)
