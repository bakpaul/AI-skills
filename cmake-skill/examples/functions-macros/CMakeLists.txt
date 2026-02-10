cmake_minimum_required(VERSION 3.15)
project(FunctionMacroExample)

#-----------------------------------------------------------------------------
# Example Function
#-----------------------------------------------------------------------------

function(add_my_library name)
    # Parse arguments with cmake_parse_arguments
    cmake_parse_arguments(
        LIB                           # Prefix
        "SHARED;STATIC;HEADER_ONLY"  # Options
        "VERSION"                     # Single-value
        "SOURCES;HEADERS;DEPS"        # Multi-value
        ${ARGN}
    )
    
    # Validate required arguments
    if(NOT DEFINED LIB_SOURCES AND NOT LIB_HEADER_ONLY)
        message(FATAL_ERROR "SOURCES required unless HEADER_ONLY")
    endif()
    
    # Create library based on type
    if(LIB_HEADER_ONLY)
        add_library(${name} INTERFACE)
        if(DEFINED LIB_HEADERS)
            target_sources(${name} INTERFACE ${LIB_HEADERS})
        endif()
    elseif(LIB_SHARED)
        add_library(${name} SHARED ${LIB_SOURCES})
    elseif(LIB_STATIC)
        add_library(${name} STATIC ${LIB_SOURCES})
    else()
        add_library(${name} ${LIB_SOURCES})
    endif()
    
    # Set version if provided
    if(DEFINED LIB_VERSION)
        set_target_properties(${name} PROPERTIES VERSION ${LIB_VERSION})
    endif()
    
    # Link dependencies
    if(DEFINED LIB_DEPS)
        target_link_libraries(${name} PUBLIC ${LIB_DEPS})
    endif()
    
    # Create alias
    add_library(${PROJECT_NAME}::${name} ALIAS ${name})
    
    message(STATUS "Created library: ${PROJECT_NAME}::${name}")
endfunction()

#-----------------------------------------------------------------------------
# Example Macro (Use sparingly!)
#-----------------------------------------------------------------------------

macro(setup_compiler_warnings)
    # This macro modifies the caller's scope
    if(MSVC)
        add_compile_options(/W4)
    else()
        add_compile_options(-Wall -Wextra -Wpedantic)
    endif()
    message(STATUS "Compiler warnings enabled")
endmacro()

#-----------------------------------------------------------------------------
# Function with PARENT_SCOPE
#-----------------------------------------------------------------------------

function(get_git_hash output_var)
    execute_process(
        COMMAND git rev-parse --short HEAD
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE git_hash
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
    
    if(git_hash)
        set(${output_var} ${git_hash} PARENT_SCOPE)
    else()
        set(${output_var} "unknown" PARENT_SCOPE)
    endif()
endfunction()

#-----------------------------------------------------------------------------
# Usage Examples
#-----------------------------------------------------------------------------

# Use the macro to set compiler warnings
setup_compiler_warnings()

# Get git hash using PARENT_SCOPE
get_git_hash(GIT_COMMIT)
message(STATUS "Git commit: ${GIT_COMMIT}")

# Create a shared library using the function
add_my_library(mylib
    SHARED
    VERSION 1.0.0
    SOURCES src/lib.cpp
    HEADERS include/lib.h
)

# The function's local variables don't leak
# message(STATUS "LIB_VERSION: ${LIB_VERSION}")  # Would be empty!

message(STATUS "")
message(STATUS "Function/Macro Example completed successfully")
message(STATUS "")
