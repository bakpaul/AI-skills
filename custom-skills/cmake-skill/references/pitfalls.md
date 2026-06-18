# Common Pitfalls and Solutions

This document covers the most common mistakes when working with CMake and how to fix them.

## 1. Wrong Target Name After find_package

### Problem
```cmake
find_package(Boost REQUIRED COMPONENTS filesystem)
target_link_libraries(myapp PRIVATE Boost)  # ❌ Wrong!
```

### Solution
```cmake
find_package(Boost REQUIRED COMPONENTS filesystem)
target_link_libraries(myapp PRIVATE Boost::filesystem)  # ✅ Correct target
```

Check package documentation for exact target names. Common patterns:
- `Package::component` (modern)
- `Package::Package` (single target)
- `PACKAGE_LIBRARIES` (old style, avoid)

---

## 2. Headers Not Found After find_package Succeeds

### Problem
`find_package()` succeeds but compilation fails with "file not found" errors.

### Diagnosis
```cmake
if(TARGET MyPackage::lib)
    get_target_property(INC MyPackage::lib INTERFACE_INCLUDE_DIRECTORIES)
    message(STATUS "Include dirs: ${INC}")
else()
    message(WARNING "Target not found!")
endif()
```

### Common Causes
1. **Not linking the target** - Must use `target_link_libraries()`
2. **Wrong target name** - Check the actual IMPORTED target name
3. **Target doesn't set includes** - Library packaging issue

### Solution
```cmake
# Make sure you're linking the target
target_link_libraries(myapp PRIVATE MyPackage::lib)
```

---

## 3. Exported Target Not Found by Consumers

### Problem
Package installs successfully but consumers get "Target not found" error.

### Checklist
- [ ] `install(EXPORT)` includes NAMESPACE
- [ ] Config.cmake includes: `include("${CMAKE_CURRENT_LIST_DIR}/MyLibTargets.cmake")`
- [ ] Export name matches in both `install(EXPORT)` and install(FILES)
- [ ] Consumer uses correct target name: `MyLib::component`

### Diagnostic Steps

**Check namespace in install:**
```cmake
install(EXPORT MyLibTargets
    NAMESPACE MyLib::              # ← Must match usage
    ...
)
```

**Check Config.cmake includes targets:**
```cmake
# In MyLibConfig.cmake
include("${CMAKE_CURRENT_LIST_DIR}/MyLibTargets.cmake")  # ← Must be present
```

**Verify consumer usage:**
```cmake
find_package(MyLib REQUIRED)
target_link_libraries(myapp PRIVATE MyLib::mylib)  # ← Namespace must match
```

---

## 4. Include Paths Wrong After Installation

### Problem
Library works during build but not after installation.

### Cause
Not using generator expressions for different build vs install paths.

### Wrong Approach
```cmake
# ❌ Same path for build and install
target_include_directories(mylib PUBLIC include)
```

### Correct Approach
```cmake
# ✅ Different paths for build vs install
target_include_directories(mylib PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)
```

**Why it matters:**
- BUILD_INTERFACE: Points to source tree during build
- INSTALL_INTERFACE: Points to install location after installation

---

## 5. Config Mode Not Finding Package

### Problem
Package installed but find_package can't find it.

### Debug Steps
```cmake
set(CMAKE_FIND_DEBUG_MODE TRUE)
find_package(MyLib CONFIG)
set(CMAKE_FIND_DEBUG_MODE FALSE)
```

### Common Solutions

**Set prefix path:**
```bash
cmake -DCMAKE_PREFIX_PATH=/path/to/install ..
```

**Or set package-specific directory:**
```bash
cmake -DMyLib_DIR=/path/to/install/lib/cmake/MyLib ..
```

### Verify Config File Location

Config file should be at one of:
- `<prefix>/lib/cmake/MyLib/MyLibConfig.cmake`
- `<prefix>/share/MyLib/MyLibConfig.cmake`

If not, check your install commands.

---

## 6. PARENT_SCOPE Not Working as Expected

### Problem
Setting variable with PARENT_SCOPE but parent doesn't see it.

### Explanation
PARENT_SCOPE creates variable in parent scope, NOT current scope.

### Wrong Approach
```cmake
function(my_func)
    set(VAR "value" PARENT_SCOPE)
    message(STATUS "${VAR}")             # ❌ Empty! Not set in current scope
endfunction()
```

### Solution 1: Set in Both Scopes
```cmake
function(my_func)
    set(VAR "value")                     # Set locally
    set(VAR "${VAR}" PARENT_SCOPE)       # Also set in parent
    message(STATUS "${VAR}")             # ✅ Now works
endfunction()
```

### Solution 2: Use return(PROPAGATE) (CMake 3.25+)
```cmake
function(my_func)
    set(VAR "value")
    message(STATUS "${VAR}")             # Works in current scope
    return(PROPAGATE VAR)                # Propagates to parent
endfunction()
```

---

## 7. Macro return() Exits Caller

### Problem
Using `return()` in a macro exits the calling function, not the macro.

### The Pitfall
```cmake
macro(check_condition)
    if(NOT CONDITION)
        return()                         # ⚠️ Returns from CALLER, not macro!
    endif()
endmacro()

function(my_function)
    check_condition()                    # If false, exits my_function!
    message(STATUS "This may not execute")
endfunction()
```

### Solution
Use a function instead of a macro:
```cmake
function(check_condition)
    if(NOT CONDITION)
        return()                         # ✅ Returns from function only
    endif()
endfunction()
```

**Why:** Macros don't create new scope, so `return()` affects the caller's scope.

---

## 8. FetchContent Slowing Configure

### Problem
Configure time is excessively long due to FetchContent.

### Solutions

**Use URL instead of GIT:**
```cmake
# ❌ Slower - clones entire repo
FetchContent_Declare(
    MyDep
    GIT_REPOSITORY https://github.com/org/mydep.git
    GIT_TAG v1.2.3
)

# ✅ Faster - downloads archive only
FetchContent_Declare(
    MyDep
    URL https://github.com/org/mydep/archive/refs/tags/v1.2.3.tar.gz
    URL_HASH SHA256=abc123...
)
```

**Use GIT_SHALLOW for large repos:**
```cmake
FetchContent_Declare(
    MyDep
    GIT_REPOSITORY https://github.com/org/mydep.git
    GIT_TAG v1.2.3
    GIT_SHALLOW TRUE                     # Don't download full history
)
```

**Try find_package first:**
```cmake
find_package(MyDep QUIET)
if(NOT MyDep_FOUND)
    FetchContent_Declare(...)
    FetchContent_MakeAvailable(MyDep)
endif()
```

---

## 9. Dependencies Not Found in Config Mode

### Problem
Your library's Config.cmake doesn't find its dependencies.

### Cause
Must use `find_dependency()` instead of `find_package()` in Config.cmake.

### Wrong Approach
```cmake
# In MyLibConfig.cmake
find_package(SomeDep REQUIRED)           # ❌ Doesn't propagate REQUIRED
```

### Correct Approach
```cmake
# In MyLibConfig.cmake
include(CMakeFindDependencyMacro)
find_dependency(SomeDep REQUIRED)        # ✅ Properly propagates
```

**Why:** `find_dependency()` properly propagates REQUIRED and other flags.

---

## 10. Linking Libraries to INTERFACE Targets

### Problem
Trying to link sources or libraries to INTERFACE target.

### Wrong Approach
```cmake
add_library(mylib INTERFACE)
target_sources(mylib PRIVATE src.cpp)    # ❌ INTERFACE has no sources
target_link_libraries(mylib PRIVATE dep) # ❌ INTERFACE can't have PRIVATE
```

### Correct Approach
```cmake
add_library(mylib INTERFACE)
# INTERFACE targets only have INTERFACE properties
target_link_libraries(mylib INTERFACE dep)  # ✅ Only INTERFACE
target_include_directories(mylib INTERFACE include/)  # ✅ Only INTERFACE
```

**When to use INTERFACE:**
- Header-only libraries
- Pure usage requirements (compile flags, etc.)

---

## Prevention Checklist

Before encountering issues:

**For library authors:**
- [ ] Use generator expressions for include directories
- [ ] Export targets with proper NAMESPACE
- [ ] Include Targets.cmake in Config.cmake
- [ ] Use find_dependency for dependencies
- [ ] Test installation locally before distributing

**For library consumers:**
- [ ] Link IMPORTED targets, not variables
- [ ] Set CMAKE_PREFIX_PATH correctly
- [ ] Use find_package CONFIG for modern packages
- [ ] Check target names in package documentation

**For everyone:**
- [ ] Use functions, not macros (default choice)
- [ ] Pin versions in FetchContent
- [ ] Verify with CMAKE_FIND_DEBUG_MODE when debugging
- [ ] Test both build and install configurations
