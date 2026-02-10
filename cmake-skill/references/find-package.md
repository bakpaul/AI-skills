# find_package() - Finding Dependencies

Complete guide to finding and using external dependencies with CMake.

### Understanding find_package()

**Two modes:**

**Module mode:**
- Searches for `Find<PackageName>.cmake` in `CMAKE_MODULE_PATH` and CMake's modules
- Typically older packages or system libraries
- Example: `FindZLIB.cmake`, `FindOpenSSL.cmake`

**Config mode:**
- Searches for `<PackageName>Config.cmake` or `<lowercase>-config.cmake`
- Modern packages that install their own config files
- Preferred for user-installed libraries
- Example: `Boost`, `Qt`, modern libraries you create

**Default search order (CMake 3.15+):**
1. Module mode first (searches Find*.cmake)
2. Config mode second (searches *Config.cmake)

**Override behavior:**
```cmake
find_package(MyLib CONFIG)        # Config mode only
find_package(MyLib MODULE)        # Module mode only
set(CMAKE_FIND_PACKAGE_PREFER_CONFIG TRUE)  # Search Config before Module
```

**Search paths for Config mode:**
- `<prefix>/lib/cmake/<Package>/`
- `<prefix>/share/<Package>/`
- Controlled by `CMAKE_PREFIX_PATH` and `<Package>_DIR`

**Common issues and fixes:**

| Problem | Likely Cause | Solution |
|---------|-------------|----------|
| Package not found | Wrong CMAKE_PREFIX_PATH | Add installation prefix to CMAKE_PREFIX_PATH |
| Wrong version found | Multiple versions installed | Use version requirement: `find_package(Lib 2.0 REQUIRED)` |
| Headers not found after find_package | Not linking correct target | Verify IMPORTED target name and link it |
| find_package succeeds but target missing | Config.cmake doesn't include Targets.cmake | Check package's Config.cmake includes the targets file |

