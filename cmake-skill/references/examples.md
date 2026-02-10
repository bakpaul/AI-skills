# Complete Working Examples

End-to-end examples demonstrating complete CMake workflows.

## Complete Example: Distributable Library

**Directory structure:**
```
MyLibrary/
├── CMakeLists.txt
├── cmake/
│   └── Config.cmake.in
├── include/
│   └── mylib/
│       └── mylib.h
└── src/
    └── mylib.cpp
```

**CMakeLists.txt:**
```cmake
cmake_minimum_required(VERSION 3.15)
project(MyLibrary VERSION 1.2.0 LANGUAGES CXX)

# Create library target
add_library(mylib SHARED
    src/mylib.cpp
)

# Create alias for consistent :: naming when used via add_subdirectory
add_library(MyLibrary::mylib ALIAS mylib)

# Set C++ standard
target_compile_features(mylib PUBLIC cxx_std_17)

# Set include directories
target_include_directories(mylib
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
)

# Example: Link dependencies
# find_package(SomeDep REQUIRED)
# target_link_libraries(mylib PUBLIC SomeDep::component)

# Installation
install(TARGETS mylib
    EXPORT MyLibraryTargets
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
    INCLUDES DESTINATION include
)

# Install headers
install(
    DIRECTORY include/
    DESTINATION include
)

# Export targets
install(EXPORT MyLibraryTargets
    FILE MyLibraryTargets.cmake
    NAMESPACE MyLibrary::
    DESTINATION lib/cmake/MyLibrary
)

# Create config file
include(CMakePackageConfigHelpers)
configure_package_config_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/Config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/MyLibraryConfig.cmake
    INSTALL_DESTINATION lib/cmake/MyLibrary
)

# Create version file
write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/MyLibraryConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

# Install config and version files
install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/MyLibraryConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/MyLibraryConfigVersion.cmake
    DESTINATION lib/cmake/MyLibrary
)
```

**cmake/Config.cmake.in:**
```cmake
@PACKAGE_INIT@

include(CMakeFindDependencyMacro)
# find_dependency(SomeDep REQUIRED)

include("${CMAKE_CURRENT_LIST_DIR}/@PROJECT_NAME@Targets.cmake")

check_required_components(@PROJECT_NAME@)
```

**Building and installing:**
```bash
cd MyLibrary
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/path/to/install
cmake --build .
cmake --install .
```

**Consumer usage:**
```cmake
# Consumer's CMakeLists.txt
cmake_minimum_required(VERSION 3.15)
project(MyApp)

find_package(MyLibrary 1.2 REQUIRED)

add_executable(myapp main.cpp)
target_link_libraries(myapp PRIVATE MyLibrary::mylib)
```

```bash
# Building consumer
cmake .. -DCMAKE_PREFIX_PATH=/path/to/install
cmake --build .
```

