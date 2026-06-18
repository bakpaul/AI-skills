# CMake Skill Examples

This directory contains working examples demonstrating the concepts taught in the CMake skill.

## Directory Structure

```
examples/
├── library/          # Example distributable library
│   ├── CMakeLists.txt
│   ├── cmake/
│   │   └── Config.cmake.in
│   ├── include/
│   │   └── example_lib.h
│   └── src/
│       └── example_lib.cpp
└── consumer/         # Example application using the library
    ├── CMakeLists.txt
    └── main.cpp
```

## Building the Library

```bash
cd examples/library
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/path/to/install
cmake --build .
cmake --install .
```

## Building the Consumer

After installing the library:

```bash
cd examples/consumer
mkdir build && cd build
cmake .. -DCMAKE_PREFIX_PATH=/path/to/install
cmake --build .
./consumer_app
```

## What These Examples Demonstrate

### Library Example
- Creating a shared/static library
- Modern target-based approach
- Public header installation
- Export and install configuration
- Config.cmake generation
- Version file creation
- Making the library distributable via find_package

### Consumer Example
- Using find_package to locate a library
- Linking against imported targets
- Proper CMAKE_PREFIX_PATH usage

## Testing the Complete Workflow

1. **Build and install the library:**
   ```bash
   cd library
   mkdir build && cd build
   cmake .. -DCMAKE_INSTALL_PREFIX=$HOME/local
   cmake --build .
   cmake --install .
   ```

2. **Build the consumer:**
   ```bash
   cd ../../consumer
   mkdir build && cd build
   cmake .. -DCMAKE_PREFIX_PATH=$HOME/local
   cmake --build .
   ```

3. **Run the consumer:**
   ```bash
   ./consumer_app
   ```

Expected output:
```
ExampleLib version: 1.0.0
5 + 7 = 12
```

## Key Concepts Demonstrated

- ✅ Target-based modern CMake
- ✅ Generator expressions for include directories
- ✅ install(TARGETS ... EXPORT)
- ✅ install(EXPORT)
- ✅ CMakePackageConfigHelpers
- ✅ Config.cmake.in template
- ✅ Version file generation
- ✅ find_package usage
- ✅ Proper namespace usage (ExampleLib::)
- ✅ Complete distributable package workflow
