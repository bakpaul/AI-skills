# CTest - Testing with CMake

CTest is CMake's built-in testing tool for running and reporting test results.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Adding Tests](#adding-tests)
3. [Running Tests](#running-tests)
4. [Test Properties](#test-properties)
5. [Advanced Features](#advanced-features)
6. [Test Framework Integration](#test-framework-integration)
7. [Best Practices](#best-practices)

## Quick Start

### Basic Setup

```cmake
cmake_minimum_required(VERSION 3.15)
project(MyProject)

enable_testing()  # Enable testing support

# Your code
add_executable(myapp src/main.cpp)

# Test executable
add_executable(test_myapp tests/test_main.cpp)

# Add test
add_test(NAME MyTest COMMAND test_myapp)
```

### Run Tests

```bash
cmake -S . -B build
cmake --build build
ctest --test-dir build              # Run all tests
ctest --test-dir build -V           # Verbose output
ctest --test-dir build --output-on-failure  # Show failures
```

## Adding Tests

### Simple Test

```cmake
add_executable(my_test tests/test.cpp)
add_test(NAME BasicTest COMMAND my_test)
```

### Test with Arguments

```cmake
add_test(NAME TestWithArgs COMMAND my_test --input data.txt --verbose)
```

### Multiple Tests from One Executable

```cmake
add_executable(calculator_tests tests/test_all.cpp)

add_test(NAME AdditionTest COMMAND calculator_tests --test=addition)
add_test(NAME SubtractionTest COMMAND calculator_tests --test=subtraction)
```

### Script Tests

```cmake
# CMake script
add_test(NAME ScriptTest 
    COMMAND ${CMAKE_COMMAND} -P ${CMAKE_SOURCE_DIR}/test.cmake
)

# Shell script
add_test(NAME ShellTest COMMAND ${CMAKE_SOURCE_DIR}/test.sh)
```

## Running Tests

### Basic Commands

```bash
ctest                          # Run all tests
ctest -V                       # Verbose output
ctest -VV                      # Extra verbose (show test output)
ctest -j8                      # Parallel (8 jobs)
ctest --output-on-failure      # Show output only for failures
ctest --rerun-failed           # Re-run only failed tests
```

### Test Selection

```bash
# By name pattern
ctest -R TestName              # Run tests matching regex
ctest -E SlowTest              # Exclude tests matching regex

# By label
ctest -L Fast                  # Run tests with "Fast" label
ctest -LE Slow                 # Exclude tests with "Slow" label

# By index
ctest -I 1,5                   # Run tests 1-5

# Control flow
ctest --stop-on-failure        # Stop at first failure
```

### Output Options

```bash
ctest --output-on-failure      # Show output for failures
ctest --output-log log.txt     # Save output to file
ctest --output-junit results.xml  # JUnit XML (for CI)
ctest --quiet                  # Summary only
```

### Advanced Options

```bash
ctest --timeout 30             # Set timeout for all tests
ctest --schedule-random        # Randomize test order
ctest --repeat until-fail:3    # Repeat until failure (max 3)
ctest --repeat until-pass:5    # Repeat until pass (max 5)
```

## Test Properties

### Common Properties

```cmake
add_test(NAME MyTest COMMAND test_exe)

set_tests_properties(MyTest PROPERTIES
    TIMEOUT 30                          # Timeout in seconds
    LABELS "Unit;Fast"                  # Organize tests
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    ENVIRONMENT "VAR=value"
    WILL_FAIL TRUE                      # Expect failure
    PASS_REGULAR_EXPRESSION "Success"   # Must match output
    FAIL_REGULAR_EXPRESSION "Error"     # Fail if matches
)
```

### Timeouts

```cmake
# Per-test timeout
set_tests_properties(SlowTest PROPERTIES TIMEOUT 300)

# Global timeout (command line)
# ctest --timeout 60
```

### Labels for Organization

```cmake
set_tests_properties(Test1 Test2 PROPERTIES LABELS "Unit;Fast")
set_tests_properties(Test3 PROPERTIES LABELS "Integration;Slow")

# Run by label: ctest -L Unit
```

### Output Validation

```cmake
# Test passes if output contains pattern
set_tests_properties(OutputTest PROPERTIES
    PASS_REGULAR_EXPRESSION "All tests passed"
)

# Test fails if output contains pattern
set_tests_properties(ErrorTest PROPERTIES
    FAIL_REGULAR_EXPRESSION "ERROR|FATAL|CRASH"
)
```

### Dependencies

```cmake
# TestB runs only if TestA passes
set_tests_properties(TestB PROPERTIES DEPENDS TestA)

# Multiple dependencies
set_tests_properties(TestC PROPERTIES DEPENDS "TestA;TestB")
```

### Resource Locks

```cmake
# Tests that can't run in parallel (share resource)
set_tests_properties(DBTest1 DBTest2 PROPERTIES
    RESOURCE_LOCK database
)
```

### Execution Order (Cost)

```cmake
# Higher cost = runs earlier (good for slow tests)
set_tests_properties(SlowTest PROPERTIES COST 100)
set_tests_properties(FastTest PROPERTIES COST 1)
```

## Advanced Features

### Fixtures (Setup/Cleanup)

Automatically run setup before tests and cleanup after.

```cmake
# Setup
add_test(NAME SetupDB COMMAND setup_database)
set_tests_properties(SetupDB PROPERTIES FIXTURES_SETUP Database)

# Tests requiring setup
add_test(NAME DBTest1 COMMAND test_queries)
add_test(NAME DBTest2 COMMAND test_inserts)
set_tests_properties(DBTest1 DBTest2 PROPERTIES FIXTURES_REQUIRED Database)

# Cleanup
add_test(NAME CleanupDB COMMAND cleanup_database)
set_tests_properties(CleanupDB PROPERTIES FIXTURES_CLEANUP Database)
```

**CTest runs:** SetupDB → DBTest1, DBTest2 → CleanupDB

### Parameterized Tests

```cmake
# Function to add parameterized tests
function(add_math_test operation expected)
    add_test(NAME Test_${operation} 
        COMMAND calculator_test ${operation} ${expected}
    )
endfunction()

add_math_test("2+2" "4")
add_math_test("3*4" "12")
add_math_test("10-3" "7")
```

### Expected Failures

```cmake
# Test is expected to fail (useful for tracking known bugs)
add_test(NAME BugTest COMMAND test_known_bug)
set_tests_properties(BugTest PROPERTIES WILL_FAIL TRUE)
```

## Test Framework Integration

### Google Test

```cmake
include(FetchContent)
FetchContent_Declare(googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG v1.14.0
)
FetchContent_MakeAvailable(googletest)

enable_testing()
include(GoogleTest)

add_executable(my_tests test_main.cpp)
target_link_libraries(my_tests GTest::gtest_main)

# Auto-discover tests
gtest_discover_tests(my_tests)
```

### Catch2

```cmake
include(FetchContent)
FetchContent_Declare(Catch2
    GIT_REPOSITORY https://github.com/catchorg/Catch2.git
    GIT_TAG v3.4.0
)
FetchContent_MakeAvailable(Catch2)

enable_testing()
include(CTest)
include(Catch)

add_executable(tests test_main.cpp)
target_link_libraries(tests Catch2::Catch2WithMain)

catch_discover_tests(tests)
```

### doctest

```cmake
include(FetchContent)
FetchContent_Declare(doctest
    GIT_REPOSITORY https://github.com/doctest/doctest.git
    GIT_TAG v2.4.11
)
FetchContent_MakeAvailable(doctest)

enable_testing()
include(doctest)

add_executable(tests test_main.cpp)
target_link_libraries(tests doctest::doctest)

doctest_discover_tests(tests)
```

## Best Practices

### 1. Use Labels to Organize Tests

```cmake
# Fast unit tests
set_tests_properties(UnitTests PROPERTIES LABELS "Unit;Fast" TIMEOUT 10)

# Slower integration tests
set_tests_properties(IntegrationTests PROPERTIES LABELS "Integration" TIMEOUT 60)

# Run fast tests: ctest -L Fast
# Run all except slow: ctest -LE Integration
```

### 2. Set Appropriate Timeouts

```cmake
set_tests_properties(UnitTests PROPERTIES TIMEOUT 10)
set_tests_properties(IntegrationTests PROPERTIES TIMEOUT 60)
set_tests_properties(E2ETests PROPERTIES TIMEOUT 300)
```

### 3. Use Fixtures for Expensive Setup

```cmake
# Setup once for multiple tests
add_test(NAME SetupTestEnv COMMAND create_test_env)
set_tests_properties(SetupTestEnv PROPERTIES FIXTURES_SETUP TestEnv)

set_tests_properties(Test1 Test2 Test3 PROPERTIES FIXTURES_REQUIRED TestEnv)

add_test(NAME CleanupTestEnv COMMAND destroy_test_env)
set_tests_properties(CleanupTestEnv PROPERTIES FIXTURES_CLEANUP TestEnv)
```

### 4. Validate Test Output

```cmake
set_tests_properties(ValidationTest PROPERTIES
    PASS_REGULAR_EXPRESSION "All checks passed"
    FAIL_REGULAR_EXPRESSION "FATAL|ERROR|CRASH"
)
```

### 5. Optional Test Building

```cmake
option(BUILD_TESTING "Build tests" ON)

if(BUILD_TESTING)
    enable_testing()
    add_subdirectory(tests)
endif()
```

### 6. Use Resource Locks for Shared Resources

```cmake
# Tests accessing same database
set_tests_properties(DBTest1 DBTest2 DBTest3 PROPERTIES
    RESOURCE_LOCK database
)

# Tests writing to same file
set_tests_properties(FileTest1 FileTest2 PROPERTIES
    RESOURCE_LOCK testfile
)
```

### 7. Cross-Platform Tests

```cmake
if(WIN32)
    add_test(NAME WindowsTest COMMAND windows_test)
elseif(UNIX)
    add_test(NAME UnixTest COMMAND unix_test)
endif()

# Or conditionally disable
add_test(NAME WindowsOnly COMMAND test.exe)
if(NOT WIN32)
    set_tests_properties(WindowsOnly PROPERTIES DISABLED TRUE)
endif()
```

### 8. CI/CD Integration

```bash
# Common CI commands
ctest --output-on-failure --timeout 300 -j4
ctest --output-junit results.xml  # For Jenkins/GitLab

# GitHub Actions example
- name: Test
  run: |
    cmake -S . -B build
    cmake --build build
    ctest --test-dir build --output-on-failure -j$(nproc)
```

## Common Patterns

### Pattern 1: Simple Project

```cmake
cmake_minimum_required(VERSION 3.15)
project(MyApp VERSION 1.0)

add_executable(myapp src/main.cpp src/utils.cpp)

enable_testing()
add_executable(test_utils tests/test_utils.cpp src/utils.cpp)
add_test(NAME UtilsTest COMMAND test_utils)
set_tests_properties(UtilsTest PROPERTIES LABELS "Unit" TIMEOUT 10)
```

### Pattern 2: Library with Tests

```cmake
add_library(mylib src/mylib.cpp)

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

# Run fast tests: ctest -L Unit
```

## Quick Reference

### Commands

```bash
ctest                          # Run all tests
ctest -V                       # Verbose
ctest -j8                      # Parallel (8 jobs)
ctest -R Name                  # Run tests matching Name
ctest -L Label                 # Run tests with Label
ctest --output-on-failure      # Show failures
ctest --rerun-failed           # Re-run failed tests
ctest --output-junit out.xml   # JUnit XML output
```

### CMake Functions

```cmake
enable_testing()                              # Enable testing
add_test(NAME name COMMAND cmd args...)      # Add test
set_tests_properties(tests PROPERTIES ...)   # Set properties
```

### Properties

```cmake
TIMEOUT seconds               # Test timeout
WILL_FAIL TRUE               # Expected to fail
LABELS "Label1;Label2"       # Organize tests
DEPENDS "Test1;Test2"        # Dependencies
FIXTURES_SETUP name          # Setup fixture
FIXTURES_REQUIRED name       # Require fixture
FIXTURES_CLEANUP name        # Cleanup fixture
RESOURCE_LOCK name           # Prevent parallel execution
WORKING_DIRECTORY path       # Working directory
ENVIRONMENT "VAR=value"      # Environment variables
PASS_REGULAR_EXPRESSION pat  # Must match output
FAIL_REGULAR_EXPRESSION pat  # Fail if matches
COST number                  # Execution order (higher = earlier)
```

## Troubleshooting

### Tests Not Found

```bash
ctest -N  # List all tests without running
```

Check:
1. Called `enable_testing()` in CMakeLists.txt?
2. Ran CMake configure after adding tests?

### Tests Fail in CI But Pass Locally

Common causes:
- Missing environment variables
- Different working directory
- Resource conflicts (parallel execution)
- Timeout too short

Solutions:
```cmake
set_tests_properties(MyTest PROPERTIES
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    RESOURCE_LOCK exclusive
    TIMEOUT 60
)
```

### Test Output Not Visible

```bash
ctest --output-on-failure  # Show failures
ctest -V                   # Show all
ctest --output-log log.txt # Save to file
```

### Test Hangs

```cmake
set_tests_properties(HangTest PROPERTIES TIMEOUT 30)
```

Or: `ctest --timeout 60`

### Parallel Tests Interfere

```cmake
set_tests_properties(Test1 Test2 PROPERTIES RESOURCE_LOCK shared_resource)
```

## References

- [CTest Documentation](https://cmake.org/cmake/help/latest/manual/ctest.1.html)
- [enable_testing()](https://cmake.org/cmake/help/latest/command/enable_testing.html)
- [add_test()](https://cmake.org/cmake/help/latest/command/add_test.html)
- [set_tests_properties()](https://cmake.org/cmake/help/latest/command/set_tests_properties.html)
