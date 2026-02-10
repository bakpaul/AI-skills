# FetchContent - Automatic Dependency Management

Complete guide to downloading and integrating dependencies at configure time.

### Dependency Management: FetchContent

**FetchContent downloads and integrates dependencies at configure time.** Alternative to pre-installing or manually managing dependencies.

**When to use FetchContent:**
- ✅ Dependencies not available as system packages
- ✅ Need specific version not installed locally
- ✅ Want reproducible builds without manual setup
- ✅ Header-only libraries
- ✅ Small to medium dependencies (configure time acceptable)

**When NOT to use FetchContent:**
- ❌ Large dependencies that slow configure significantly (>30s)
- ❌ When pre-installed packages are standard and preferred
- ❌ Dependencies need build-time installation (use ExternalProject)

**Basic pattern:**
```cmake
include(FetchContent)

# Declare the dependency
FetchContent_Declare(
    json
    GIT_REPOSITORY https://github.com/nlohmann/json.git
    GIT_TAG        v3.11.2  # ⚠️ Use specific tag, not "main"!
)

# Make available (downloads and adds as subdirectory)
FetchContent_MakeAvailable(json)

# Use the target
target_link_libraries(myapp PRIVATE nlohmann_json::nlohmann_json)
```

**Content sources:**

```cmake
# Git repository (slower but always current)
FetchContent_Declare(
    MyLib
    GIT_REPOSITORY https://github.com/user/mylib.git
    GIT_TAG        v1.2.3                    # Specific tag
    GIT_SHALLOW    TRUE                      # Faster if you don't need history
)

# URL to archive (faster than Git)
FetchContent_Declare(
    MyLib
    URL            https://github.com/user/mylib/archive/refs/tags/v1.2.3.tar.gz
    URL_HASH       SHA256=abc123...         # Recommended for security
)

# Single file
FetchContent_Declare(
    SingleHeader
    URL                 https://raw.githubusercontent.com/user/lib/main/header.h
    DOWNLOAD_NO_EXTRACT TRUE                # Added in CMake 3.18
)
```

**Best practices:**

1. **Use specific versions** for reproducibility:
   ```cmake
   GIT_TAG v3.11.2  # ✅ GOOD: Specific version
   GIT_TAG main     # ❌ BAD: Changes over time
   ```

2. **Try find_package first** (hybrid approach):
   ```cmake
   find_package(MyLib QUIET)
   if(NOT MyLib_FOUND)
       FetchContent_Declare(...)
       FetchContent_MakeAvailable(MyLib)
   endif()
   ```

3. **Configure fetched dependencies**:
   ```cmake
   # Set options before MakeAvailable
   set(JSON_BuildTests OFF CACHE INTERNAL "")
   FetchContent_MakeAvailable(json)
   ```

4. **Control verbosity**:
   ```cmake
   set(FETCHCONTENT_QUIET OFF)  # See download progress
   ```

**For library authors - Make your library FetchContent-friendly:**

```cmake
# In your library's CMakeLists.txt

# Detect if being used as subdirectory (via FetchContent or add_subdirectory)
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    # Building standalone - enable tests, examples, etc.
    option(MYLIB_BUILD_TESTS "Build tests" ON)
    option(MYLIB_BUILD_EXAMPLES "Build examples" ON)
else()
    # Being used as subdirectory - don't clutter consumer's build
    option(MYLIB_BUILD_TESTS "Build tests" OFF)
    option(MYLIB_BUILD_EXAMPLES "Build examples" OFF)
endif()

# Only add tests/examples if enabled
if(MYLIB_BUILD_TESTS)
    add_subdirectory(tests)
endif()
```

**Troubleshooting:**

| Issue | Cause | Solution |
|-------|-------|----------|
| Slow configure | Git repository with large history | Use URL instead, or GIT_SHALLOW TRUE |
| Target not found after MakeAvailable | Target name mismatch | Check dependency's CMakeLists.txt for actual target names |
| Version conflicts | Multiple FetchContent_Declare for same dependency | First declaration wins; use find_package first pattern |
| Build failures | Missing dependency requirements | Check dependency's documentation for prerequisites |

