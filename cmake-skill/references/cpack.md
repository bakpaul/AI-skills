# CPack - Creating Distributable Packages

CPack is CMake's built-in tool for creating installer packages (installers, archives, DEB, RPM, etc.).

## Table of Contents

1. [Quick Start](#quick-start)
2. [Package Generators](#package-generators)
3. [Essential Configuration](#essential-configuration)
4. [Platform-Specific Packaging](#platform-specific-packaging)
5. [Component-Based Installation](#component-based-installation)
6. [Best Practices](#best-practices)

## Quick Start

### Minimal Setup

```cmake
# After project() and install() commands
set(CPACK_PACKAGE_VENDOR "YourCompany")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE.txt")
include(CPack)  # Must be last
```

### Create Package

```bash
cmake -S . -B build
cmake --build build
cd build
cpack                    # Default generator
cpack -G TGZ            # Specific format
cpack -G "DEB;RPM"      # Multiple formats
```

### Complete Basic Example

```cmake
cmake_minimum_required(VERSION 3.15)
project(MyApp VERSION 1.2.3)

add_executable(myapp src/main.cpp)
install(TARGETS myapp DESTINATION bin)
install(FILES README.md LICENSE.txt DESTINATION .)

# CPack configuration
set(CPACK_PACKAGE_VENDOR "YourCompany")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "My Application")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE.txt")
set(CPACK_GENERATOR "TGZ;ZIP")
include(CPack)
```

## Package Generators

### Archive (Cross-platform)

```cmake
set(CPACK_GENERATOR "TGZ")      # tar.gz
set(CPACK_GENERATOR "ZIP")      # zip
set(CPACK_GENERATOR "TGZ;ZIP")  # Multiple
```

### Linux

```cmake
# Debian (.deb)
set(CPACK_GENERATOR "DEB")
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Your Name <email@example.com>")
set(CPACK_DEBIAN_PACKAGE_DEPENDS "libstdc++6, libc6")

# RPM (.rpm)
set(CPACK_GENERATOR "RPM")
set(CPACK_RPM_PACKAGE_LICENSE "MIT")
set(CPACK_RPM_PACKAGE_REQUIRES "glibc >= 2.17")
```

### macOS

```cmake
set(CPACK_GENERATOR "DragNDrop")  # DMG
set(CPACK_DMG_VOLUME_NAME "${PROJECT_NAME}")
```

### Windows

```cmake
# NSIS installer
set(CPACK_GENERATOR "NSIS")
set(CPACK_NSIS_DISPLAY_NAME "My Application")
set(CPACK_NSIS_MUI_ICON "${CMAKE_SOURCE_DIR}/icon.ico")

# WiX (.msi)
set(CPACK_GENERATOR "WIX")
set(CPACK_WIX_UPGRADE_GUID "12345678-1234-1234-1234-123456789ABC")
```

### Platform-Specific Auto-Selection

```cmake
if(WIN32)
    set(CPACK_GENERATOR "NSIS;ZIP")
elseif(APPLE)
    set(CPACK_GENERATOR "DragNDrop")
elseif(UNIX)
    set(CPACK_GENERATOR "DEB;RPM;TGZ")
endif()
```

## Essential Configuration

### Required Variables

```cmake
set(CPACK_PACKAGE_NAME "MyApp")
set(CPACK_PACKAGE_VENDOR "YourCompany")
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE.txt")
```

### Common Variables

```cmake
# Description
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Brief description")
set(CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_SOURCE_DIR}/Description.txt")

# Output control
set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-${CMAKE_SYSTEM_NAME}")
set(CPACK_PACKAGE_DIRECTORY "${CMAKE_BINARY_DIR}/packages")

# Additional files
set(CPACK_RESOURCE_FILE_README "${CMAKE_SOURCE_DIR}/README.md")
```

### Source Packages

```cmake
set(CPACK_SOURCE_GENERATOR "TGZ;ZIP")
set(CPACK_SOURCE_IGNORE_FILES
    "/\\.git/"
    "/build/"
    "/\\.vscode/"
    "\\.swp$"
)
```

Create with: `cpack --config CPackSourceConfig.cmake`

## Platform-Specific Packaging

### Debian/Ubuntu

```cmake
set(CPACK_GENERATOR "DEB")
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Name <email@example.com>")  # Required
set(CPACK_DEBIAN_PACKAGE_SECTION "devel")
set(CPACK_DEBIAN_PACKAGE_DEPENDS "libstdc++6 (>= 5.2), libc6 (>= 2.17)")
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)  # Auto-detect dependencies
```

**Test:** `dpkg -c package.deb` (list), `sudo dpkg -i package.deb` (install)

### RPM

```cmake
set(CPACK_GENERATOR "RPM")
set(CPACK_RPM_PACKAGE_LICENSE "MIT")  # Required
set(CPACK_RPM_PACKAGE_GROUP "Development/Tools")
set(CPACK_RPM_PACKAGE_REQUIRES "glibc >= 2.17")
set(CPACK_RPM_PACKAGE_AUTOREQ ON)  # Auto-detect dependencies
```

**Test:** `rpm -qlp package.rpm` (list), `sudo rpm -i package.rpm` (install)

### Windows NSIS

```cmake
set(CPACK_GENERATOR "NSIS")
set(CPACK_NSIS_DISPLAY_NAME "My Application")
set(CPACK_NSIS_MUI_ICON "${CMAKE_SOURCE_DIR}/icon.ico")
set(CPACK_NSIS_MENU_LINKS
    "bin/myapp.exe" "My Application"
    "https://example.com" "Website"
)
set(CPACK_NSIS_MODIFY_PATH ON)  # Add to PATH
```

### macOS DMG

```cmake
set(CPACK_GENERATOR "DragNDrop")
set(CPACK_DMG_VOLUME_NAME "${PROJECT_NAME}")
set(CPACK_DMG_FORMAT "UDBZ")  # Compressed
```

## Component-Based Installation

Create separate packages for runtime, development files, and documentation.

### Define Components

```cmake
# Runtime
install(TARGETS myapp COMPONENT Runtime DESTINATION bin)

# Development
install(TARGETS mylib COMPONENT Development DESTINATION lib)
install(DIRECTORY include/ COMPONENT Development DESTINATION include)

# Documentation
install(FILES README.md COMPONENT Documentation DESTINATION share/doc)
```

### Configure CPack Components

```cmake
set(CPACK_COMPONENTS_ALL Runtime Development Documentation)

# Component details
set(CPACK_COMPONENT_RUNTIME_DISPLAY_NAME "Application Runtime")
set(CPACK_COMPONENT_RUNTIME_REQUIRED ON)

set(CPACK_COMPONENT_DEVELOPMENT_DISPLAY_NAME "Development Files")
set(CPACK_COMPONENT_DEVELOPMENT_DEPENDS Runtime)

include(CPack)
```

### Build Component Packages

```bash
cpack                                    # All components
cpack -D CPACK_COMPONENTS_ALL=Runtime   # Specific component
```

## Best Practices

### 1. Use Project Version

```cmake
project(MyApp VERSION 1.2.3)
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
```

### 2. Include License

```cmake
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE.txt")
```

### 3. Set Package Filename

```cmake
set(CPACK_PACKAGE_FILE_NAME 
    "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-${CMAKE_SYSTEM_NAME}")
```

### 4. Exclude Build Artifacts from Source Packages

```cmake
set(CPACK_SOURCE_IGNORE_FILES
    "/\\.git/" "/build.*/" "/\\.vscode/" "/\\.idea/"
    "\\.swp$" "~$" "/CMakeCache\\.txt$" "/CMakeFiles/"
)
```

### 5. Test Installation

```bash
# Build package
cpack

# Test installation
# Linux DEB: sudo dpkg -i package.deb
# Linux RPM: sudo rpm -i package.rpm
# Verify files: dpkg -L package-name (or rpm -ql)
```

### 6. Handle Dependencies

```cmake
# Auto-detect (recommended)
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
set(CPACK_RPM_PACKAGE_AUTOREQ ON)

# Manual specification
set(CPACK_DEBIAN_PACKAGE_DEPENDS "lib1 (>= 1.0), lib2")
set(CPACK_RPM_PACKAGE_REQUIRES "lib1 >= 1.0, lib2")
```

### 7. Sign Packages (Production)

```bash
dpkg-sig --sign builder package.deb              # Debian
rpm --addsign package.rpm                        # RPM
codesign -s "Developer ID" package.dmg           # macOS
signtool sign /f cert.pfx /p pass installer.exe  # Windows
```

## Quick Reference

### Essential Commands

```bash
cpack                    # Default generator
cpack -G TGZ            # Specific format
cpack -G "DEB;RPM"      # Multiple formats
cpack --config CPackSourceConfig.cmake  # Source package
```

### Key Variables

| Variable | Purpose |
|----------|---------|
| CPACK_GENERATOR | Package format (TGZ, DEB, RPM, NSIS, etc.) |
| CPACK_PACKAGE_NAME | Package name |
| CPACK_PACKAGE_VERSION | Version string |
| CPACK_PACKAGE_VENDOR | Company/author |
| CPACK_RESOURCE_FILE_LICENSE | License file path |

### Generator-Specific

| Generator | Key Variables |
|-----------|--------------|
| DEB | CPACK_DEBIAN_PACKAGE_MAINTAINER (required), CPACK_DEBIAN_PACKAGE_DEPENDS |
| RPM | CPACK_RPM_PACKAGE_LICENSE (required), CPACK_RPM_PACKAGE_REQUIRES |
| NSIS | CPACK_NSIS_DISPLAY_NAME, CPACK_NSIS_MUI_ICON |
| DragNDrop | CPACK_DMG_VOLUME_NAME |

## Troubleshooting

### Package is Empty
- Run `cmake --install build --prefix staging --verbose` first
- Check install() commands are correct
- Verify files in staging directory

### Wrong Files in Package
```bash
tar -tzf package.tar.gz      # List archive contents
dpkg -c package.deb          # List DEB contents
rpm -qlp package.rpm         # List RPM contents
```

### Dependencies Not Detected
```cmake
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
set(CPACK_RPM_PACKAGE_AUTOREQ ON)
```

## References

- [CPack Documentation](https://cmake.org/cmake/help/latest/module/CPack.html)
- [DEB Generator](https://cmake.org/cmake/help/latest/cpack_gen/deb.html)
- [RPM Generator](https://cmake.org/cmake/help/latest/cpack_gen/rpm.html)
- [NSIS Generator](https://cmake.org/cmake/help/latest/cpack_gen/nsis.html)
