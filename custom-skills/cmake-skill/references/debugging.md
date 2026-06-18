# Debugging CMake Issues

Systematic approaches to troubleshooting CMake configuration and build problems.

## Workflow Guidelines

### Systematic Debugging Approach

When user reports an issue, use this systematic process:

**1. Understand the context**
- What are they trying to accomplish?
- What exact error messages appear?
- What have they already tried?
- What CMake version are they using?

**2. Categorize the issue**
- Build configuration issue (CMakeLists.txt syntax, logic)
- Dependency finding issue (find_package not working)
- Include/link issue (headers or libraries not found during build)
- Installation issue (files not installed correctly)
- Export/packaging issue (consumers can't find the package)

**3. Apply appropriate diagnostic approach**

For **find_package issues:**
```cmake
# Step 1: Enable debug mode
set(CMAKE_FIND_DEBUG_MODE TRUE)
find_package(MyPackage)
set(CMAKE_FIND_DEBUG_MODE FALSE)

# Step 2: Check search paths
message(STATUS "CMAKE_PREFIX_PATH: ${CMAKE_PREFIX_PATH}")
message(STATUS "MyPackage_DIR: ${MyPackage_DIR}")
message(STATUS "CMAKE_MODULE_PATH: ${CMAKE_MODULE_PATH}")

# Step 3: Verify what was found
if(MyPackage_FOUND)
    message(STATUS "MyPackage found")
    message(STATUS "MyPackage_VERSION: ${MyPackage_VERSION}")
    message(STATUS "MyPackage_INCLUDE_DIRS: ${MyPackage_INCLUDE_DIRS}")
endif()
```

For **target/linking issues:**
```cmake
# Check if target exists after find_package
if(TARGET MyPackage::component)
    message(STATUS "Target exists")
else()
    message(WARNING "Target MyPackage::component not found")
endif()

# Print target properties
get_target_property(INC MyPackage::component INTERFACE_INCLUDE_DIRECTORIES)
message(STATUS "Include dirs: ${INC}")

get_target_property(LIBS MyPackage::component INTERFACE_LINK_LIBRARIES)
message(STATUS "Link libs: ${LIBS}")
```

For **installation issues:**
```cmake
# Verbose installation
cmake --install . --verbose

# Check what would be installed
cmake --install . --dry-run
```

**4. Verify against documentation**
- If uncertain about command behavior → Search CMake docs
- If user's code should work but doesn't → Check docs for version changes
- If suggesting a fix → Verify it's the modern recommended approach

### Creating Complete Examples

When providing CMakeLists.txt examples:

**1. Always show complete, working code**
```cmake
# ✅ GOOD - Complete example
cmake_minimum_required(VERSION 3.15)
project(MyLib VERSION 1.0.0)

add_library(mylib SHARED src/mylib.cpp)
target_include_directories(mylib PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

# ❌ BAD - Fragment without context
add_library(mylib SHARED src/mylib.cpp)
# ... user doesn't know where this goes or what's needed before/after
```

**2. Include directory structure when relevant**
```
myproject/
├── CMakeLists.txt
├── include/
│   └── mylib.h
└── src/
    └── mylib.cpp
```

**3. Add comments explaining non-obvious parts**
```cmake
# Generator expressions ensure different paths for build vs install
target_include_directories(mylib PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>  # When building
    $<INSTALL_INTERFACE:include>                            # When installed
)
```

**4. Show both producer and consumer sides for packaging**
```cmake
# --- Library side (mylib/CMakeLists.txt) ---
install(EXPORT MyLibTargets ...)

# --- Consumer side (app/CMakeLists.txt) ---
find_package(MyLib REQUIRED)
target_link_libraries(myapp PRIVATE MyLib::mylib)
```

### Response Strategy

**Explanations:**
- Start with **high-level concept** before diving into details
- Use **concrete examples** to illustrate abstract ideas
- **Anticipate follow-up questions** and address proactively
- **Link concepts** to show how they fit together

**Code examples:**
- Provide **complete, working** examples
- Use **modern CMake syntax** (target-based)
- Add **comments** for non-obvious parts
- Show **both library and consumer** sides when relevant

**Error resolution:**
- Provide **specific diagnostic steps**, not generic advice
- List **potential causes in order of likelihood**
- **Verify assumptions** with documentation if uncertain
- If previous advice didn't work, **search documentation** before trying again

**Tone:**
- Be **helpful and constructive**
- **Acknowledge** when you're verifying information
- **Explain reasoning** behind recommendations
- Be **honest** about version-specific features or limitations

