cmake_minimum_required(VERSION 3.14)
project(FetchContentExample CXX)

include(FetchContent)

# Example 1: Fetch a header-only library (fmt)
FetchContent_Declare(
    fmt
    GIT_REPOSITORY https://github.com/fmtlib/fmt.git
    GIT_TAG        9.1.0
)

# Example 2: Fetch from URL (faster than Git)
FetchContent_Declare(
    json
    URL https://github.com/nlohmann/json/archive/refs/tags/v3.11.2.zip
    URL_HASH SHA256=d69f9deb6a75e2580465c6c4c5111b89c4dc2fa94e3a85fcd2ffcd9a143d9273
)

# Configure dependencies before making them available
set(FMT_INSTALL OFF CACHE BOOL "" FORCE)
set(JSON_BuildTests OFF CACHE BOOL "" FORCE)

# Make both dependencies available
FetchContent_MakeAvailable(fmt json)

# Create your application
add_executable(fetch_example main.cpp)

# Link against the fetched dependencies
target_link_libraries(fetch_example 
    PRIVATE 
        fmt::fmt
        nlohmann_json::nlohmann_json
)

target_compile_features(fetch_example PRIVATE cxx_std_17)

message(STATUS "")
message(STATUS "FetchContent Example Configuration:")
message(STATUS "  fmt populated: ${fmt_POPULATED}")
message(STATUS "  json populated: ${json_POPULATED}")
message(STATUS "")
