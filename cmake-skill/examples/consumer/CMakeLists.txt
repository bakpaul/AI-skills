cmake_minimum_required(VERSION 3.15)
project(ExampleConsumer CXX)

# Find the installed ExampleLib package
find_package(ExampleLib REQUIRED)

# Create the executable
add_executable(consumer_app main.cpp)

# Link against the library
target_link_libraries(consumer_app PRIVATE ExampleLib::example_lib)

# Set C++ standard
target_compile_features(consumer_app PRIVATE cxx_std_17)

message(STATUS "")
message(STATUS "Consumer Configuration:")
message(STATUS "  ExampleLib found: ${ExampleLib_FOUND}")
message(STATUS "  ExampleLib version: ${ExampleLib_VERSION}")
message(STATUS "  ExampleLib dir: ${ExampleLib_DIR}")
message(STATUS "")
