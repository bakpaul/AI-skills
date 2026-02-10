# CMake Targets - Deep Dive

Understanding targets is fundamental to modern CMake.

### Targets: The Core of Modern CMake

**What is a target?**
A target represents a build artifact (executable/library) or a logical grouping of build settings. Targets are the foundation of modern CMake.

**Target types:**
| Type | Created by | Use case |
|------|-----------|----------|
| Executable | `add_executable()` | Programs to run |
| Library (STATIC/SHARED/MODULE) | `add_library()` | Code to link |
| INTERFACE | `add_library(... INTERFACE)` | Header-only libs or pure requirements |
| IMPORTED | `find_package()` | Pre-built external libraries |
| ALIAS | `add_library(... ALIAS ...)` | Alternative name for existing target |

**Why targets matter:**
- **Transitive dependencies**: Link to A, automatically get A's dependencies
- **Encapsulation**: Each target owns its build requirements
- **Clean interfaces**: PUBLIC/PRIVATE/INTERFACE visibility controls
- **Proper propagation**: Include paths, compile flags propagate correctly

**Example demonstrating transitivity:**
```cmake
# LibA needs LibB
add_library(LibA src/a.cpp)
target_link_libraries(LibA PUBLIC LibB::core)

# App links LibA, automatically gets LibB too
add_executable(myapp main.cpp)
target_link_libraries(myapp PRIVATE LibA)  # Gets both LibA and LibB
```

