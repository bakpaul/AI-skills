# Functions, Macros, and Scope Management

Complete guide to creating reusable CMake code with functions and macros.

### Functions, Macros, and Scope

**Critical difference: Functions create new scope, macros don't.**

#### Functions

Functions create **new variable scope**. Variables set inside are local.

```cmake
function(my_function arg1 arg2)
    # arg1, arg2 are parameters
    # ARGC = total number of arguments
    # ARGV = list of all arguments
    # ARGN = arguments beyond named parameters
    
    set(LOCAL_VAR "value")              # Local to function
    message(STATUS "Local: ${LOCAL_VAR}")
    
    set(RESULT "value" PARENT_SCOPE)    # Set in parent scope
endfunction()

my_function(val1 val2 val3)
# LOCAL_VAR is not defined here
# RESULT is defined (via PARENT_SCOPE)
```

**Returning values from functions:**

Method 1 - PARENT_SCOPE:
```cmake
function(get_version OUT_VAR)
    set(${OUT_VAR} "1.2.3" PARENT_SCOPE)
endfunction()

get_version(MY_VERSION)
message(STATUS "Version: ${MY_VERSION}")  # Prints: Version: 1.2.3
```

Method 2 - return(PROPAGATE) (CMake 3.25+):
```cmake
function(get_version)
    set(VERSION "1.2.3")
    return(PROPAGATE VERSION)            # Propagates VERSION to parent
endfunction()

get_version()
message(STATUS "Version: ${VERSION}")    # Prints: Version: 1.2.3
```

**return() behavior in functions:**
```cmake
function(early_exit)
    if(SOME_CONDITION)
        return()                         # Exits function only
    endif()
    # Continue execution...
endfunction()
```

#### Macros

Macros operate **in caller's scope**. No new scope created.

```cmake
macro(my_macro arg1)
    set(VAR "value")                     # Sets in caller's scope
    message(STATUS "Arg1: ${arg1}")      # ${arg1} is text-replaced
endmacro()

my_macro(test)
message(STATUS "VAR: ${VAR}")            # VAR exists and equals "value"
```

**Critical differences:**

| Aspect | Function | Macro |
|--------|----------|-------|
| Scope | New scope created | Uses caller's scope |
| Arguments | Real variables | Text substitution |
| PARENT_SCOPE | Needed to set parent variables | Not needed, already in parent scope |
| return() | Exits function | Exits caller's scope ⚠️ |
| Use case | Most code (encapsulation) | Control flow, text manipulation |

**⚠️ Macro return() pitfall:**
```cmake
macro(check_condition)
    if(NOT CONDITION)
        return()                         # ⚠️ Returns from CALLER, not macro!
    endif()
endmacro()

function(my_function)
    check_condition()                    # If false, exits my_function!
    # This may not execute
endfunction()
```

**When to use each:**

Use **functions** (default):
- ✅ General purpose reusable code
- ✅ Need encapsulation
- ✅ Want to return values cleanly
- ✅ Need local variables that don't leak

Use **macros** (rare):
- ✅ Control flow that affects caller (like if/endif)
- ✅ Text manipulation where text substitution is beneficial
- ✅ Performance-critical code (minimal overhead)
- ✅ Need to modify caller's variables directly

#### Parsing Arguments: cmake_parse_arguments

Modern way to handle optional and keyword arguments.

```cmake
function(my_install)
    cmake_parse_arguments(
        PARSE_ARGV 0              # For functions: use PARSE_ARGV
        ARG                       # Prefix for result variables
        "VERBOSE"                 # Options (boolean flags)
        "DESTINATION"             # Single-value keywords
        "TARGETS;FILES"           # Multi-value keywords
    )
    
    # Access parsed arguments:
    # ARG_VERBOSE         - TRUE if -VERBOSE passed
    # ARG_DESTINATION     - Value of DESTINATION
    # ARG_TARGETS         - List of targets
    # ARG_FILES           - List of files
    # ARG_UNPARSED_ARGUMENTS - Arguments that don't match
    
    if(ARG_VERBOSE)
        message(STATUS "Installing to ${ARG_DESTINATION}")
    endif()
    
    foreach(target IN LISTS ARG_TARGETS)
        install(TARGETS ${target} DESTINATION ${ARG_DESTINATION})
    endforeach()
endfunction()

# Usage:
my_install(
    VERBOSE
    DESTINATION lib
    TARGETS mylib yourlib
    FILES config.h utils.h
)
```

**For macros** use `${ARGN}` instead:
```cmake
macro(my_macro)
    cmake_parse_arguments(
        ARG
        "VERBOSE"
        "OUTPUT"
        "SOURCES"
        ${ARGN}                    # Not PARSE_ARGV for macros
    )
endmacro()
```

**Checking required arguments:**
```cmake
function(my_function)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "REQUIRED_ARG" "")
    
    if(NOT DEFINED ARG_REQUIRED_ARG)
        message(FATAL_ERROR "REQUIRED_ARG must be provided")
    endif()
endfunction()
```

#### Scope Rules Summary

**Directory scope:**
- Each `CMakeLists.txt` has its own scope
- `add_subdirectory()` creates child scope inheriting parent variables
- Children get **copies** - changes don't affect parent (unless PARENT_SCOPE)

**Function scope:**
- New local scope with inherited parent variables (read-only copies)
- Use PARENT_SCOPE or return(PROPAGATE) to modify parent

**Macro scope:**
- No new scope - operates in caller's scope
- All changes affect caller directly

**Cache variables:**
- Global across all scopes
- `set(VAR value CACHE TYPE "doc")` or `option(VAR "doc" default)`
- Persist between CMake runs
- Can be overridden on command line: `cmake -DVAR=value`

**Target scope:**
- Targets are **globally scoped** once created
- Created in function/subdirectory are accessible project-wide
- Target properties are different from variables

