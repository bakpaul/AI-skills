# CPack - Creating Distributable Packages

CPack is CMake's built-in tool for creating installer packages (installers, archives, DEB, RPM, etc.).

## Table of Contents

1. [Overview](#overview)
2. [Basic Usage](#basic-usage)
3. [Package Generators](#package-generators)
4. [Configuration Variables](#configuration-variables)
5. [Common Patterns](#common-patterns)
6. [Platform-Specific Packaging](#platform-specific-packaging)
7. [Component-Based Installation](#component-based-installation)
8. [Best Practices](#best-practices)

## Overview

**What is CPack?**
CPack creates distributable packages from your installed files. It runs after `cmake --install` and packages the installed files.

**Workflow:**
```
cmake --build build
cmake --install build --prefix staging
cpack --config build/CPackConfig.cmake
```

**Common use cases:**
- Creating installers for end users
- Distributing binary releases
- Creating platform-specific packages (DEB, RPM, MSI, DMG)
- Making source distributions

## Basic Usage

### Minimal CPack Configuration

Add to your CMakeLists.txt:

```cmake
# After project() and install() commands

# Package metadata
set(CPACK_PACKAGE_NAME "MyApp")
set(CPACK_PACKAGE_VENDOR "YourCompany")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Brief description")
set(CPACK_PACKAGE_VERSION_MAJOR "1")
set(CPACK_PACKAGE_VERSION_MINOR "0")
set(CPACK_PACKAGE_VERSION_PATCH "0")

# Include CPack module (must be last)
include(CPack)
```

### Creating a Package

```bash
# Build and install
cmake -S . -B build
cmake --build build
cmake --install build --prefix staging

# Create package
cd build
cpack
```

This creates packages in the build directory (e.g., `MyApp-1.0.0-Linux.tar.gz`).

## Package Generators

CPack supports multiple package formats (generators):

### Archive Generators (Cross-platform)

```cmake
# TGZ (tar.gz)
set(CPACK_GENERATOR "TGZ")

# ZIP
set(CPACK_GENERATOR "ZIP")

# Multiple formats
set(CPACK_GENERATOR "TGZ;ZIP")
```

### Linux Generators

```cmake
# Debian package (.deb)
set(CPACK_GENERATOR "DEB")
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Your Name <email@example.com>")
set(CPACK_DEBIAN_PACKAGE_DEPENDS "libstdc++6, libc6")

# RPM package (.rpm)
set(CPACK_GENERATOR "RPM")
set(CPACK_RPM_PACKAGE_LICENSE "MIT")
set(CPACK_RPM_PACKAGE_REQUIRES "glibc >= 2.17")
```

### macOS Generators

```cmake
# DMG (Disk Image)
set(CPACK_GENERATOR "DragNDrop")

# macOS Bundle
set(CPACK_GENERATOR "Bundle")
set(CPACK_BUNDLE_NAME "MyApp")
set(CPACK_BUNDLE_ICON "${CMAKE_SOURCE_DIR}/icon.icns")
```

### Windows Generators

```cmake
# NSIS installer
set(CPACK_GENERATOR "NSIS")
set(CPACK_NSIS_DISPLAY_NAME "My Application")
set(CPACK_NSIS_HELP_LINK "https://example.com/help")
set(CPACK_NSIS_URL_INFO_ABOUT "https://example.com")
set(CPACK_NSIS_CONTACT "support@example.com")

# WiX installer (.msi)
set(CPACK_GENERATOR "WIX")
set(CPACK_WIX_UPGRADE_GUID "12345678-1234-1234-1234-123456789ABC")
set(CPACK_WIX_LICENSE_RTF "${CMAKE_SOURCE_DIR}/License.rtf")
```

### Specifying Generator at Runtime

```bash
# Override generator from command line
cpack -G TGZ
cpack -G "DEB;RPM"
```

## Configuration Variables

### Essential Variables

```cmake
# Package identification
set(CPACK_PACKAGE_NAME "MyApp")
set(CPACK_PACKAGE_VENDOR "YourCompany")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "One-line description")
set(CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_SOURCE_DIR}/Description.txt")

# Version
set(CPACK_PACKAGE_VERSION_MAJOR "${PROJECT_VERSION_MAJOR}")
set(CPACK_PACKAGE_VERSION_MINOR "${PROJECT_VERSION_MINOR}")
set(CPACK_PACKAGE_VERSION_PATCH "${PROJECT_VERSION_PATCH}")
# Or use:
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")

# Files to include
set(CPACK_PACKAGE_INSTALL_DIRECTORY "MyApp")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE.txt")
set(CPACK_RESOURCE_FILE_README "${CMAKE_SOURCE_DIR}/README.md")
```

### Output Control

```cmake
# Package file name format
set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-${CMAKE_SYSTEM_NAME}")

# Output directory
set(CPACK_PACKAGE_DIRECTORY "${CMAKE_BINARY_DIR}/packages")

# Source package name
set(CPACK_SOURCE_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-Source")
```

### Files to Exclude

```cmake
# Ignore patterns for source packages
set(CPACK_SOURCE_IGNORE_FILES
    "/\\.git/"
    "/\\.github/"
    "/build/"
    "/\\.vscode/"
    "\\.swp$"
    "\\.orig$"
    "/\\.DS_Store$"
)
```

## Common Patterns

### Pattern 1: Simple Binary Distribution

```cmake
cmake_minimum_required(VERSION 3.15)
project(MyApp VERSION 1.2.3)

# Your build configuration
add_executable(myapp src/main.cpp)

# Installation
install(TARGETS myapp DESTINATION bin)
install(FILES README.md LICENSE.txt DESTINATION .)

# CPack configuration
set(CPACK_PACKAGE_VENDOR "YourCompany")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "My Application")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE.txt")
set(CPACK_GENERATOR "TGZ;ZIP")

include(CPack)
```

**Creates:** `MyApp-1.2.3-Linux.tar.gz` and `MyApp-1.2.3-Linux.zip`

### Pattern 2: Platform-Specific Packages

```cmake
# Platform detection
if(WIN32)
    set(CPACK_GENERATOR "NSIS;ZIP")
    set(CPACK_NSIS_DISPLAY_NAME "${PROJECT_NAME}")
    set(CPACK_NSIS_MUI_ICON "${CMAKE_SOURCE_DIR}/resources/icon.ico")
elseif(APPLE)
    set(CPACK_GENERATOR "DragNDrop")
    set(CPACK_DMG_VOLUME_NAME "${PROJECT_NAME}")
elseif(UNIX)
    set(CPACK_GENERATOR "DEB;RPM;TGZ")
    
    # Debian-specific
    set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Your Name <email@example.com>")
    set(CPACK_DEBIAN_PACKAGE_SECTION "devel")
    set(CPACK_DEBIAN_PACKAGE_PRIORITY "optional")
    
    # RPM-specific
    set(CPACK_RPM_PACKAGE_LICENSE "MIT")
    set(CPACK_RPM_PACKAGE_GROUP "Development/Tools")
endif()

include(CPack)
```

### Pattern 3: Library with Development Files

```cmake
# Install library and headers
install(TARGETS mylib EXPORT MyLibTargets
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
)
install(DIRECTORY include/ DESTINATION include)

# Install CMake config files
install(EXPORT MyLibTargets
    FILE MyLibTargets.cmake
    NAMESPACE MyLib::
    DESTINATION lib/cmake/MyLib
)
install(FILES MyLibConfig.cmake MyLibConfigVersion.cmake
    DESTINATION lib/cmake/MyLib
)

# CPack
set(CPACK_PACKAGE_NAME "libmylib-dev")
set(CPACK_DEBIAN_PACKAGE_SECTION "libdevel")
set(CPACK_GENERATOR "DEB;TGZ")

include(CPack)
```

### Pattern 4: Source Package

```cmake
# Create source packages
set(CPACK_SOURCE_GENERATOR "TGZ;ZIP")
set(CPACK_SOURCE_IGNORE_FILES
    "/\\.git/"
    "/build/"
    "/\\..*\\.swp$"
    "/CMakeCache\\.txt$"
    "/CMakeFiles/"
)

include(CPack)
```

**Create source package:**
```bash
cd build
cpack --config CPackSourceConfig.cmake
```

## Platform-Specific Packaging

### Debian/Ubuntu (.deb)

```cmake
set(CPACK_GENERATOR "DEB")

# Required
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Your Name <email@example.com>")

# Recommended
set(CPACK_DEBIAN_PACKAGE_SECTION "devel")
set(CPACK_DEBIAN_PACKAGE_PRIORITY "optional")
set(CPACK_DEBIAN_PACKAGE_HOMEPAGE "https://example.com")

# Dependencies
set(CPACK_DEBIAN_PACKAGE_DEPENDS "libstdc++6 (>= 5.2), libc6 (>= 2.17)")
set(CPACK_DEBIAN_PACKAGE_SUGGESTS "optional-package")

# Package name
set(CPACK_DEBIAN_FILE_NAME "DEB-DEFAULT")  # Use default naming

# Post-install script
set(CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA
    "${CMAKE_SOURCE_DIR}/debian/postinst"
    "${CMAKE_SOURCE_DIR}/debian/prerm"
)
```

**Testing:**
```bash
dpkg -c MyApp-1.0.0-Linux.deb    # List contents
sudo dpkg -i MyApp-1.0.0-Linux.deb    # Install
sudo dpkg -r myapp                     # Remove
```

### RedHat/Fedora (.rpm)

```cmake
set(CPACK_GENERATOR "RPM")

# Required
set(CPACK_RPM_PACKAGE_LICENSE "MIT")

# Recommended
set(CPACK_RPM_PACKAGE_GROUP "Development/Tools")
set(CPACK_RPM_PACKAGE_URL "https://example.com")
set(CPACK_RPM_PACKAGE_DESCRIPTION "Longer description here")

# Dependencies
set(CPACK_RPM_PACKAGE_REQUIRES "glibc >= 2.17, libstdc++ >= 5.2")
set(CPACK_RPM_PACKAGE_SUGGESTS "optional-package")

# Package name
set(CPACK_RPM_FILE_NAME "RPM-DEFAULT")

# Post-install
set(CPACK_RPM_POST_INSTALL_SCRIPT_FILE "${CMAKE_SOURCE_DIR}/rpm/postinstall.sh")
set(CPACK_RPM_PRE_UNINSTALL_SCRIPT_FILE "${CMAKE_SOURCE_DIR}/rpm/preuninstall.sh")
```

**Testing:**
```bash
rpm -qlp MyApp-1.0.0-Linux.rpm    # List contents
sudo rpm -i MyApp-1.0.0-Linux.rpm    # Install
sudo rpm -e myapp                     # Remove
```

### Windows NSIS

```cmake
set(CPACK_GENERATOR "NSIS")

# Display information
set(CPACK_NSIS_DISPLAY_NAME "My Application")
set(CPACK_NSIS_PACKAGE_NAME "MyApp")
set(CPACK_NSIS_HELP_LINK "https://example.com/help")
set(CPACK_NSIS_URL_INFO_ABOUT "https://example.com")
set(CPACK_NSIS_CONTACT "support@example.com")

# Icons
set(CPACK_NSIS_MUI_ICON "${CMAKE_SOURCE_DIR}/resources/icon.ico")
set(CPACK_NSIS_MUI_UNIICON "${CMAKE_SOURCE_DIR}/resources/uninstall.ico")

# Start menu
set(CPACK_NSIS_MENU_LINKS
    "bin/myapp.exe" "My Application"
    "https://example.com" "Website"
)

# Desktop shortcut
set(CPACK_NSIS_CREATE_ICONS_EXTRA
    "CreateShortCut '$DESKTOP\\\\MyApp.lnk' '$INSTDIR\\\\bin\\\\myapp.exe'"
)
set(CPACK_NSIS_DELETE_ICONS_EXTRA
    "Delete '$DESKTOP\\\\MyApp.lnk'"
)

# Modify PATH
set(CPACK_NSIS_MODIFY_PATH ON)
```

### macOS DMG

```cmake
set(CPACK_GENERATOR "DragNDrop")

# DMG settings
set(CPACK_DMG_VOLUME_NAME "${PROJECT_NAME}")
set(CPACK_DMG_FORMAT "UDBZ")  # Compressed
set(CPACK_DMG_BACKGROUND_IMAGE "${CMAKE_SOURCE_DIR}/resources/background.png")

# Window position and size
set(CPACK_DMG_DS_STORE_SETUP_SCRIPT "${CMAKE_SOURCE_DIR}/cmake/DMGSetup.scpt")
```

## Component-Based Installation

Useful for creating separate packages (e.g., runtime, development, documentation).

### Defining Components

```cmake
# Install runtime
install(TARGETS myapp
    COMPONENT Runtime
    DESTINATION bin
)

# Install development files
install(TARGETS mylib
    COMPONENT Development
    DESTINATION lib
)
install(DIRECTORY include/
    COMPONENT Development
    DESTINATION include
)

# Install documentation
install(FILES README.md
    COMPONENT Documentation
    DESTINATION share/doc
)
```

### CPack Component Configuration

```cmake
# Enable component-based packaging
set(CPACK_COMPONENTS_ALL Runtime Development Documentation)

# Component descriptions
set(CPACK_COMPONENT_RUNTIME_DISPLAY_NAME "Application Runtime")
set(CPACK_COMPONENT_RUNTIME_DESCRIPTION "Executable and required libraries")
set(CPACK_COMPONENT_RUNTIME_REQUIRED ON)

set(CPACK_COMPONENT_DEVELOPMENT_DISPLAY_NAME "Development Files")
set(CPACK_COMPONENT_DEVELOPMENT_DESCRIPTION "Headers and libraries for development")
set(CPACK_COMPONENT_DEVELOPMENT_DEPENDS Runtime)

set(CPACK_COMPONENT_DOCUMENTATION_DISPLAY_NAME "Documentation")
set(CPACK_COMPONENT_DOCUMENTATION_DESCRIPTION "User documentation")

include(CPack)
```

### Creating Component Packages

```bash
# Create all packages
cpack

# Create specific component package
cpack -D CPACK_COMPONENTS_ALL=Runtime

# DEB creates separate .deb for each component
# Result: myapp-runtime_1.0.0.deb, myapp-development_1.0.0.deb
```

## Best Practices

### 1. Always Set Essential Metadata

```cmake
# Minimum required
set(CPACK_PACKAGE_NAME "MyApp")
set(CPACK_PACKAGE_VENDOR "YourCompany")
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE.txt")
```

### 2. Use PROJECT_VERSION

```cmake
# In project() command
project(MyApp VERSION 1.2.3)

# CPack automatically uses it
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
```

### 3. Test on Target Platform

```bash
# Create package
cpack

# Test installation
# Linux:
sudo dpkg -i MyApp-1.0.0-Linux.deb
sudo rpm -i MyApp-1.0.0-Linux.rpm

# Windows:
# Run the installer
MyApp-1.0.0-win64.exe

# macOS:
# Open the DMG and drag to Applications
```

### 4. Provide Uninstall Support

Most generators handle this automatically, but for archives:

```cmake
# Create uninstall target (for development)
configure_file(
    "${CMAKE_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in"
    "${CMAKE_BINARY_DIR}/cmake_uninstall.cmake"
    IMMEDIATE @ONLY
)

add_custom_target(uninstall
    COMMAND ${CMAKE_COMMAND} -P ${CMAKE_BINARY_DIR}/cmake_uninstall.cmake
)
```

### 5. Version Your Packages Properly

```cmake
# Good: Includes version in filename
set(CPACK_PACKAGE_FILE_NAME 
    "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-${CMAKE_SYSTEM_NAME}")

# Result: MyApp-1.2.3-Linux.tar.gz
```

### 6. Exclude Build Artifacts from Source Packages

```cmake
set(CPACK_SOURCE_IGNORE_FILES
    "/\\.git/"
    "/\\.github/"
    "/build.*/"
    "/\\.vscode/"
    "/\\.idea/"
    "\\.user$"
    "\\.swp$"
    "\\.orig$"
    "~$"
    "/CMakeCache\\.txt$"
    "/CMakeFiles/"
    "/CPackConfig\\.cmake$"
    "/CPackSourceConfig\\.cmake$"
    "/cmake_install\\.cmake$"
)
```

### 7. Provide Package-Specific Descriptions

```cmake
# Generic description (all packages)
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "My Application")

# Debian-specific (longer)
set(CPACK_DEBIAN_PACKAGE_DESCRIPTION 
"My Application - Full Description
 .
 This is a longer description that explains what the application
 does and why someone would want to use it.
 .
 Multiple paragraphs are supported.")
```

### 8. Handle Dependencies Correctly

```cmake
# Debian
set(CPACK_DEBIAN_PACKAGE_DEPENDS "libstdc++6 (>= 5.2), libssl3 (>= 3.0)")
set(CPACK_DEBIAN_PACKAGE_SUGGESTS "optional-package")
set(CPACK_DEBIAN_PACKAGE_RECOMMENDS "recommended-package")

# RPM
set(CPACK_RPM_PACKAGE_REQUIRES "glibc >= 2.17, openssl-libs >= 3.0")
set(CPACK_RPM_PACKAGE_SUGGESTS "optional-package")
```

### 9. Sign Your Packages (Production)

```bash
# Debian
dpkg-sig --sign builder MyApp-1.0.0-Linux.deb

# RPM
rpm --addsign MyApp-1.0.0-Linux.rpm

# macOS
codesign -s "Developer ID" MyApp-1.0.0-Darwin.dmg

# Windows (via signtool.exe)
signtool sign /f certificate.pfx /p password MyApp-1.0.0-win64.exe
```

### 10. Document Installation Instructions

Create INSTALL.txt with platform-specific instructions:

```markdown
# Installation Instructions

## Linux (Debian/Ubuntu)
sudo dpkg -i MyApp-1.0.0-Linux.deb

## Linux (RedHat/Fedora)
sudo rpm -i MyApp-1.0.0-Linux.rpm

## macOS
Open MyApp-1.0.0-Darwin.dmg and drag to Applications

## Windows
Run MyApp-1.0.0-win64.exe and follow the installer
```

## Quick Reference

### Minimal Configuration

```cmake
set(CPACK_PACKAGE_VENDOR "YourCompany")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE.txt")
include(CPack)
```

### Create Package

```bash
cd build
cpack                    # Creates default package
cpack -G TGZ            # Creates tar.gz
cpack -G "DEB;RPM"      # Creates both
```

### Common Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| CPACK_GENERATOR | Package format | "TGZ", "DEB", "NSIS" |
| CPACK_PACKAGE_NAME | Package name | "MyApp" |
| CPACK_PACKAGE_VERSION | Version | "1.2.3" |
| CPACK_PACKAGE_VENDOR | Company/author | "YourCompany" |
| CPACK_PACKAGE_DESCRIPTION_SUMMARY | Short description | "My Application" |

### Generator-Specific Variables

| Generator | Key Variables |
|-----------|--------------|
| DEB | CPACK_DEBIAN_PACKAGE_MAINTAINER, CPACK_DEBIAN_PACKAGE_DEPENDS |
| RPM | CPACK_RPM_PACKAGE_LICENSE, CPACK_RPM_PACKAGE_REQUIRES |
| NSIS | CPACK_NSIS_DISPLAY_NAME, CPACK_NSIS_MUI_ICON |
| DragNDrop | CPACK_DMG_VOLUME_NAME, CPACK_DMG_BACKGROUND_IMAGE |

## Troubleshooting

### Package is Empty

**Check:**
1. Did you run `cmake --install` before `cpack`?
2. Are your install() commands correct?
3. Check with: `cmake --install build --prefix staging --verbose`

### Wrong Files in Package

**Debug:**
```bash
# For archives
tar -tzf MyApp-1.0.0-Linux.tar.gz

# For DEB
dpkg -c MyApp-1.0.0-Linux.deb

# For RPM  
rpm -qlp MyApp-1.0.0-Linux.rpm
```

### Dependencies Not Detected (DEB/RPM)

Use automatic dependency detection:
```cmake
# Debian
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)

# RPM
set(CPACK_RPM_PACKAGE_AUTOREQ ON)
```

### CPack Not Found

CPack comes with CMake. If missing:
```bash
cmake --version    # Verify CMake is installed
which cpack        # Should be in same directory as cmake
```

## References

- [CPack Documentation](https://cmake.org/cmake/help/latest/module/CPack.html)
- [CPackDeb](https://cmake.org/cmake/help/latest/cpack_gen/deb.html)
- [CPackRPM](https://cmake.org/cmake/help/latest/cpack_gen/rpm.html)
- [CPackNSIS](https://cmake.org/cmake/help/latest/cpack_gen/nsis.html)
