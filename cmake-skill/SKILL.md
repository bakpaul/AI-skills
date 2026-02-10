---
name: cmake
description: Expert guidance for modern CMake (3.15+), covering library creation, dependency management, testing with CTest, package distribution with CPack, and debugging. Use when users need help writing CMakeLists.txt, setting up tests, debugging CMake issues, creating distributable packages, or generating installers. Always verifies information against CMake documentation when uncertain or when previous advice didn't work as expected.
---

# CMake Expert Skill

Expert guidance on modern CMake (3.15+) focusing on practical implementation, debugging, and best practices.

## Core Principles

### Documentation-First Approach

**Always verify against CMake documentation when:**
- There is any uncertainty about behavior
- Previous advice didn't work as expected
- User reports unexpected behavior
- Dealing with version-specific features

Use web_search to check https://cmake.org/cmake/help/latest/

### Modern CMake Practices

- Use **target-based** approach (not directory-based variables)
- Prefer `target_*` commands over global variables
- Use IMPORTED targets from `find_package()` CONFIG mode
- Always specify visibility: `PUBLIC`, `PRIVATE`, `INTERFACE`

### Scope

**IN SCOPE:**
- Writing/debugging CMakeLists.txt
- Creating distributable libraries
- Understanding targets and dependencies
- Dependency management (find_package, FetchContent)
- Installation and export configurations
- Functions, macros, and scope management

**OUT OF SCOPE:**
- General C/C++ compilation errors (unless CMake-related)
- IDE-specific settings
- Non-CMake build systems

## Quick Reference

For common patterns and immediate lookup, use:
- **Creating libraries**: See `references/quick-reference.md`
- **Debugging**: See `references/debugging.md`
- **Complete examples**: See `references/examples.md`

### Most Common Patterns

**Basic library:**
```cmake
add_library(mylib SHARED src/mylib.cpp)
add_library(MyLib::mylib ALIAS mylib)

target_include_directories(mylib PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)
```

**Installation:**
```cmake
install(TARGETS mylib EXPORT MyLibTargets
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
    INCLUDES DESTINATION include
)

install(EXPORT MyLibTargets
    FILE MyLibTargets.cmake
    NAMESPACE MyLib::
    DESTINATION lib/cmake/MyLib
)
```

**Consumer usage:**
```cmake
find_package(MyLib REQUIRED)
target_link_libraries(myapp PRIVATE MyLib::mylib)
```

## Key Concepts

### Targets

A target represents a build artifact or logical grouping. Modern CMake is target-centric.

**Types:**
- **Executable**: Created with `add_executable()`
- **Library** (STATIC/SHARED/MODULE): Created with `add_library()`
- **INTERFACE**: Header-only or pure requirements
- **IMPORTED**: Pre-built libraries from `find_package()`
- **ALIAS**: Alternative name for existing target

**Why targets matter:**
- Enable transitive dependency propagation
- Encapsulate build requirements
- Provide clean interfaces
- Allow proper dependency resolution

For detailed target information, see `references/targets.md`.

### find_package

Searches for external dependencies in two modes:

**Module mode** (first): Looks for `Find<Package>.cmake` in CMAKE_MODULE_PATH
**Config mode** (second): Looks for `<Package>Config.cmake` in install locations

**Common issues:**
- Package not found → Check CMAKE_PREFIX_PATH
- Headers not found after find_package → Check target linking
- Wrong version → Use version requirements

For debugging find_package, see `references/debugging.md`.

### FetchContent

Downloads and integrates dependencies at configure time.

**When to use:**
- ✅ Dependencies not available as system packages
- ✅ Need specific version not installed
- ✅ Want reproducible builds

**When NOT to use:**
- ❌ Large dependencies (>30s configure)
- ❌ Pre-installed packages preferred

For complete FetchContent guide, see `references/fetchcontent.md`.

### Functions and Macros

**Key difference:** Functions create new scope, macros don't.

**Use functions (default):**
- General purpose code
- Need encapsulation
- Want to return values

**Use macros (rare):**
- Control flow affecting caller
- Text manipulation
- Performance-critical code

For detailed scope management, see `references/functions-macros.md`.

### CTest - Running Tests

CTest is CMake's built-in testing tool for running and reporting test results.

**Basic usage:**
```cmake
# Enable testing
enable_testing()

# Add test executable
add_executable(my_test tests/test.cpp)

# Register test
add_test(NAME MyTest COMMAND my_test)

# Set properties (optional)
set_tests_properties(MyTest PROPERTIES
    TIMEOUT 30
    LABELS "Unit"
)
```

**Running tests:**
```bash
cmake --build build
ctest --test-dir build                # Run all tests
ctest --test-dir build -j8           # Parallel execution
ctest --test-dir build -R TestName   # Run specific test
ctest --test-dir build -L Unit       # Run by label
```

**Key features:**
- Parallel test execution
- Test filtering and selection
- Timeout handling
- Integration with test frameworks (GTest, Catch2)
- Output validation

For complete CTest guide including fixtures, test properties, CI integration, and test frameworks, see `references/ctest.md`.

### CPack - Creating Installers

CPack creates distributable packages (installers, .deb, .rpm, .dmg, etc.) from your installed files.

**Basic usage:**
```cmake
# After project() and install() commands
set(CPACK_PACKAGE_VENDOR "YourCompany")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE.txt")
set(CPACK_GENERATOR "TGZ;ZIP")  # Or DEB, RPM, NSIS, DragNDrop, etc.
include(CPack)
```

**Creating packages:**
```bash
cmake --build build
cmake --install build --prefix staging
cd build && cpack
```

**Common generators:**
- **TGZ/ZIP** - Cross-platform archives
- **DEB** - Debian/Ubuntu packages
- **RPM** - RedHat/Fedora packages
- **NSIS** - Windows installer
- **DragNDrop** - macOS DMG

For complete CPack guide including platform-specific packaging, component installation, and best practices, see `references/cpack.md`.

## Workflow Guidelines

### When User Asks for Help

1. **Understand context** - What are they trying to accomplish?
2. **Check documentation** - If uncertain, verify against CMake docs
3. **Provide complete examples** - Full CMakeLists.txt when relevant
4. **Address debugging systematically** - Use diagnostic steps from `references/debugging.md`

### Response Strategy

**Explanations:**
- Start with high-level concept before details
- Use concrete examples
- Anticipate follow-up questions
- Link concepts together

**Code examples:**
- Provide complete, working examples
- Use modern CMake syntax
- Add comments for non-obvious parts
- Show both producer and consumer sides

**Error resolution:**
- Provide specific diagnostic steps
- List potential causes in order of likelihood
- Verify assumptions with documentation
- If previous advice didn't work, search docs before trying again

## Common Tasks

### Creating a Distributable Library

**Quick checklist:**
- [ ] Create library target with `add_library()`
- [ ] Set include directories with generator expressions
- [ ] Link dependencies with proper visibility
- [ ] Install targets with `install(TARGETS ... EXPORT ...)`
- [ ] Install headers with `install(DIRECTORY include/)`
- [ ] Create Config.cmake with `configure_package_config_file()`
- [ ] Create version file with `write_basic_package_version_file()`
- [ ] Install config files

For complete example, see `references/examples.md`.

### Debugging find_package Issues

**Systematic approach:**
1. Enable debug mode: `set(CMAKE_FIND_DEBUG_MODE TRUE)`
2. Check search paths: `message(STATUS "CMAKE_PREFIX_PATH: ${CMAKE_PREFIX_PATH}")`
3. Verify package location
4. Check package naming (case sensitive!)

For detailed troubleshooting, see `references/debugging.md`.

### Common Pitfalls

**Headers not found after find_package:**
- Cause: Not linking the target
- Solution: Use `target_link_libraries(myapp PRIVATE Package::target)`

**Exported target not found:**
- Cause: Config.cmake doesn't include Targets file
- Solution: Add `include("${CMAKE_CURRENT_LIST_DIR}/Targets.cmake")`

**PARENT_SCOPE confusion:**
- Cause: PARENT_SCOPE sets in parent, not current scope
- Solution: Set locally first, then set with PARENT_SCOPE

For all common pitfalls, see `references/pitfalls.md`.

## Reference Documentation

The skill includes detailed reference documentation:

- **`references/quick-reference.md`** - Copy-paste ready syntax and checklists
- **`references/pitfalls.md`** - Common mistakes and solutions
- **`references/ctest.md`** - Testing with CTest (running tests, test properties, fixtures, CI integration)
- **`references/cpack.md`** - Creating distributable packages (installers, .deb, .rpm, etc.)
- **`references/targets.md`** - Deep dive on targets and properties (to be created as needed)
- **`references/find-package.md`** - Complete find_package guide (to be created as needed)
- **`references/fetchcontent.md`** - FetchContent patterns and best practices (to be created as needed)
- **`references/functions-macros.md`** - Functions, macros, scope, and argument parsing (to be created as needed)
- **`references/debugging.md`** - Systematic debugging approaches (to be created as needed)
- **`references/examples.md`** - Complete working examples (to be created as needed)

**When to consult references:**
- User needs detailed explanation beyond quick answer
- Complex topic requires comprehensive coverage
- User asks for complete examples
- Debugging requires systematic approach

## Remember

- **Documentation over assumptions** - Verify against CMake docs when uncertain
- **Target-centric thinking** - Modern CMake is all about targets
- **Complete examples** - Users need working code, not fragments
- **Systematic debugging** - Follow logical troubleshooting process
- **User feedback** - If approach didn't work, investigate before alternatives
- **Use reference docs** - Detailed information in `references/` folder

## Response Checklist

Before responding, verify:
- [ ] Understood what user is trying to accomplish
- [ ] Checked appropriate reference docs if needed
- [ ] Verified information if uncertain
- [ ] Providing complete, working examples
- [ ] Using modern CMake syntax
- [ ] Explaining non-obvious parts
- [ ] Anticipating follow-up questions
