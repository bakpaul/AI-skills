# Quick Reference

Copy-paste ready CMake patterns and syntax.

## Table of Contents

1. [Common Task Checklists](#common-task-checklists)
2. [Quick Syntax Reference](#quick-syntax-reference)
3. [Comparison Tables](#comparison-tables)

## Common Task Checklists

### Creating a Distributable Library

- [ ] `add_library()` with source files
- [ ] `target_include_directories()` with BUILD_INTERFACE and INSTALL_INTERFACE
- [ ] `target_link_libraries()` for dependencies with visibility keywords
- [ ] `install(TARGETS ... EXPORT ...)` with LIBRARY/ARCHIVE/RUNTIME destinations
- [ ] `install(EXPORT ... NAMESPACE ...)` for targets
- [ ] `install(DIRECTORY include/)` for headers
- [ ] `configure_package_config_file()` for Config.cmake
- [ ] `write_basic_package_version_file()` for versioning

### Consuming a Library

- [ ] `find_package(MyLib REQUIRED)` or `find_package(MyLib CONFIG REQUIRED)`
- [ ] Link with: `target_link_libraries(myapp PRIVATE MyLib::component)`
- [ ] Set `CMAKE_PREFIX_PATH` if package not found

### Debugging find_package

- [ ] Enable: `set(CMAKE_FIND_DEBUG_MODE TRUE)`
- [ ] Check: `message(STATUS "CMAKE_PREFIX_PATH: ${CMAKE_PREFIX_PATH}")`
- [ ] Verify: Package name case-sensitivity
- [ ] Look for: `<prefix>/lib/cmake/<Package>/` or `<prefix>/share/<Package>/`

## Quick Syntax Reference

### Target Creation

```cmake
# Executable
add_executable(myapp main.cpp)

# Library (STATIC, SHARED, or INTERFACE)
add_library(mylib STATIC src/lib.cpp)

# Alias for consistent naming
add_library(MyLib::mylib ALIAS mylib)
```

### Target Properties

```cmake
# Include directories
target_include_directories(mylib
    PUBLIC                                    # Consumers need these
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE                                   # Only this target needs
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# Link libraries
target_link_libraries(mylib
    PUBLIC ThirdParty::PublicDep              # Consumers need this
    PRIVATE ThirdParty::InternalDep           # Only this target needs
)

# Compile features
target_compile_features(mylib PUBLIC cxx_std_17)
```

### Installation

```cmake
# Install targets
install(TARGETS mylib
    EXPORT MyLibTargets
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
    INCLUDES DESTINATION include              # Sets INTERFACE_INCLUDE_DIRECTORIES
)

# Install headers
install(
    DIRECTORY include/
    DESTINATION include
)

# Export targets
install(EXPORT MyLibTargets
    FILE MyLibTargets.cmake
    NAMESPACE MyLib::
    DESTINATION lib/cmake/MyLib
)
```

### Package Configuration

```cmake
include(CMakePackageConfigHelpers)

# Create config file
configure_package_config_file(
    cmake/Config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/MyLibConfig.cmake
    INSTALL_DESTINATION lib/cmake/MyLib
)

# Create version file
write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/MyLibConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion            # Or: AnyNewerVersion, ExactVersion
)

# Install config files
install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/MyLibConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/MyLibConfigVersion.cmake
    DESTINATION lib/cmake/MyLib
)
```

### FetchContent

```cmake
include(FetchContent)

# Declare dependency
FetchContent_Declare(
    MyDep
    GIT_REPOSITORY https://github.com/org/mydep.git
    GIT_TAG        v1.2.3                     # Use specific tag!
)

# Make available
FetchContent_MakeAvailable(MyDep)

# Use the target
target_link_libraries(myapp PRIVATE MyDep::core)
```

### Functions with Parsed Arguments

```cmake
function(my_install)
    cmake_parse_arguments(
        PARSE_ARGV 0                          # For functions
        ARG                                   # Prefix
        "VERBOSE"                             # Options (boolean flags)
        "DESTINATION"                         # Single-value keywords
        "TARGETS;FILES"                       # Multi-value keywords
    )
    
    # Access with ARG_VERBOSE, ARG_DESTINATION, ARG_TARGETS, ARG_FILES
    
    if(ARG_VERBOSE)
        message(STATUS "Installing to ${ARG_DESTINATION}")
    endif()
endfunction()

# Usage
my_install(
    VERBOSE
    DESTINATION lib
    TARGETS mylib yourlib
    FILES config.h
)
```

## Comparison Tables

### Target Types

| Type | Created by | Use case |
|------|-----------|----------|
| Executable | `add_executable()` | Programs to run |
| Library (STATIC/SHARED/MODULE) | `add_library()` | Code to link |
| INTERFACE | `add_library(... INTERFACE)` | Header-only libs or pure requirements |
| IMPORTED | `find_package()` | Pre-built external libraries |
| ALIAS | `add_library(... ALIAS ...)` | Alternative name for existing target |

### Visibility Keywords

| Keyword | Effect | When to Use |
|---------|--------|-------------|
| PUBLIC | Used by target AND its consumers | Public API, headers that consumers need |
| PRIVATE | Used only by this target | Implementation details |
| INTERFACE | Used only by consumers | Header-only libraries, usage requirements |

### find_package Issues and Solutions

| Problem | Likely Cause | Solution |
|---------|-------------|----------|
| Package not found | Wrong CMAKE_PREFIX_PATH | Add installation prefix to CMAKE_PREFIX_PATH |
| Wrong version found | Multiple versions installed | Use version requirement: `find_package(Lib 2.0 REQUIRED)` |
| Headers not found after find_package | Not linking correct target | Verify IMPORTED target name and link it |
| find_package succeeds but target missing | Config.cmake doesn't include Targets.cmake | Check package's Config.cmake includes the targets file |

### Function vs Macro

| Aspect | Function | Macro |
|--------|----------|-------|
| Scope | New scope created | Uses caller's scope |
| Arguments | Real variables | Text substitution |
| PARENT_SCOPE | Needed to set parent variables | Not needed, already in parent scope |
| return() | Exits function | Exits caller's scope ⚠️ |
| Use case | Most code (encapsulation) | Control flow, text manipulation |

### FetchContent Decision Guide

| Situation | Use FetchContent? | Alternative |
|-----------|------------------|-------------|
| Dependency not installed | ✅ Yes | Manual installation |
| Need specific version | ✅ Yes | Install specific version |
| Reproducible builds wanted | ✅ Yes | Version pinning |
| Large dependency (>30s) | ❌ No | Use find_package or ExternalProject |
| Pre-installed package available | ❌ Prefer find_package first | Hybrid approach |
| Header-only library | ✅ Yes | Fast and simple |

### Generator Expressions

| Expression | Meaning | Use case |
|------------|---------|----------|
| `$<BUILD_INTERFACE:...>` | Value when building | Include directories during build |
| `$<INSTALL_INTERFACE:...>` | Value when installed | Include directories after installation |
| `$<TARGET_PROPERTY:tgt,prop>` | Get target property | Conditional settings |
| `$<CONFIG:cfg>` | True for config type | Debug vs Release settings |

## Good vs Bad Examples

### Modern Target-Based Approach

```cmake
# ✅ GOOD - Modern target-based
target_link_libraries(myapp PRIVATE MyLib::core)
target_include_directories(myapp PRIVATE include/)
target_compile_features(myapp PRIVATE cxx_std_17)

# ❌ BAD - Old directory-based
link_libraries(mylib)
include_directories(include/)
set(CMAKE_CXX_STANDARD 17)
```

### Generator Expressions for Install

```cmake
# ✅ GOOD - Different paths for build vs install
target_include_directories(mylib PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

# ❌ BAD - Same path for both (won't work after install)
target_include_directories(mylib PUBLIC include)
```

### Version Pinning in FetchContent

```cmake
# ✅ GOOD - Specific version
FetchContent_Declare(
    MyDep
    GIT_REPOSITORY https://github.com/org/mydep.git
    GIT_TAG        v1.2.3                     # Reproducible!
)

# ❌ BAD - Floating reference
FetchContent_Declare(
    MyDep
    GIT_REPOSITORY https://github.com/org/mydep.git
    GIT_TAG        main                       # Changes over time
)
```

### Target Linking After find_package

```cmake
# ✅ GOOD - Link the target
find_package(Boost REQUIRED COMPONENTS filesystem)
target_link_libraries(myapp PRIVATE Boost::filesystem)

# ❌ BAD - Wrong target name
find_package(Boost REQUIRED COMPONENTS filesystem)
target_link_libraries(myapp PRIVATE Boost)              # Not the right target!
```

## Config.cmake.in Template

```cmake
@PACKAGE_INIT@

include(CMakeFindDependencyMacro)

# Find public dependencies your library needs
# find_dependency(SomeDependency 1.2)

# Include the targets file (created by install(EXPORT))
include("${CMAKE_CURRENT_LIST_DIR}/@PROJECT_NAME@Targets.cmake")

# Check that all required components are found
check_required_components(@PROJECT_NAME@)
```

## Quick Command Reference

```bash
# Configure
cmake -S . -B build -DCMAKE_PREFIX_PATH=/path/to/deps

# Build
cmake --build build

# Install
cmake --install build --prefix /path/to/install

# Install with verbose output
cmake --install build --verbose

# Install dry-run
cmake --install build --dry-run
```
