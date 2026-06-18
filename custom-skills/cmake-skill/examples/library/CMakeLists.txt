cmake_minimum_required(VERSION 3.15)
project(ExampleLib VERSION 1.0.0 LANGUAGES CXX)

# Option to build as shared or static
option(BUILD_SHARED_LIBS "Build shared libraries" ON)

#-----------------------------------------------------------------------------
# Create the library
#-----------------------------------------------------------------------------

add_library(example_lib
    src/example_lib.cpp
)

# Create an alias for consistent usage
add_library(ExampleLib::example_lib ALIAS example_lib)

# Configure the library
target_include_directories(example_lib
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# Set C++ standard
target_compile_features(example_lib PUBLIC cxx_std_17)

# Optional: Link dependencies
# find_package(Boost REQUIRED COMPONENTS system)
# target_link_libraries(example_lib
#     PUBLIC Boost::system
# )

#-----------------------------------------------------------------------------
# Installation
#-----------------------------------------------------------------------------

include(GNUInstallDirs)

# Install the library binary
install(TARGETS example_lib
    EXPORT ExampleLibTargets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

# Install public headers
install(DIRECTORY include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

# Install the export set
install(EXPORT ExampleLibTargets
    FILE ExampleLibTargets.cmake
    NAMESPACE ExampleLib::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/ExampleLib
)

#-----------------------------------------------------------------------------
# Package configuration
#-----------------------------------------------------------------------------

include(CMakePackageConfigHelpers)

# Generate the Config file
configure_package_config_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/Config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/ExampleLibConfig.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/ExampleLib
)

# Generate the version file
write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/ExampleLibConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

# Install config files
install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/ExampleLibConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/ExampleLibConfigVersion.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/ExampleLib
)

#-----------------------------------------------------------------------------
# Summary
#-----------------------------------------------------------------------------

message(STATUS "")
message(STATUS "ExampleLib Configuration Summary:")
message(STATUS "  Version: ${PROJECT_VERSION}")
message(STATUS "  Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "  Shared libs: ${BUILD_SHARED_LIBS}")
message(STATUS "  Install prefix: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "")
