# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About SOFA

SOFA (Simulation Open Framework Architecture) is a C++ framework for real-time multi-physics simulation. It uses a scene-graph model where simulation objects are composed of components communicating via `Data<T>` fields and `Link` dependencies.

## Build System

Requires CMake 3.22+. Use presets from `CMakePresets.json`:

```bash
# Configure (choose a preset)
cmake --preset minimal    # Core library only
cmake --preset standard   # Core + default GUI + Python
cmake --preset full       # All plugins

# Build
cmake --build <build-dir> -j$(nproc)
```

Key CMake options:
- `SOFA_BUILD_TESTS=ON` — enable test compilation (default: OFF)
- `SOFA_FLOATING_POINT_TYPE` — `"double"` (default) or `"float"`
- `SOFA_USE_CCACHE=ON` — faster rebuilds
- `SOFA_WITH_OPENGL=ON` — OpenGL rendering support
- `SOFA_ALLOW_FETCH_DEPENDENCIES=ON` — auto-fetch GTest, nlohmann_json, etc.

### CMake Module Structure

Each SOFA module (framework library, component, or plugin) follows this pattern:

```cmake
cmake_minimum_required(VERSION 3.22)
project(Sofa.Component.MyModule LANGUAGES CXX)

set(SOFACOMPONENTMYMODULE_SOURCE_DIR "src/sofa/component/mymodule")

set(HEADER_FILES
    ${SOFACOMPONENTMYMODULE_SOURCE_DIR}/config.h.in
    ${SOFACOMPONENTMYMODULE_SOURCE_DIR}/init.h
    ${SOFACOMPONENTMYMODULE_SOURCE_DIR}/MyComponent.h
    ${SOFACOMPONENTMYMODULE_SOURCE_DIR}/MyComponent.inl
)

set(SOURCE_FILES
    ${SOFACOMPONENTMYMODULE_SOURCE_DIR}/init.cpp
    ${SOFACOMPONENTMYMODULE_SOURCE_DIR}/MyComponent.cpp
)

sofa_find_package(Sofa.Simulation.Core REQUIRED)

add_library(${PROJECT_NAME} SHARED ${HEADER_FILES} ${SOURCE_FILES})
target_link_libraries(${PROJECT_NAME} PUBLIC Sofa.Simulation.Core)

sofa_create_package_with_targets(
    PACKAGE_NAME ${PROJECT_NAME}
    PACKAGE_VERSION ${Sofa_VERSION}
    TARGETS ${PROJECT_NAME} AUTO_SET_TARGET_PROPERTIES
    INCLUDE_SOURCE_DIR "src"
    INCLUDE_INSTALL_DIR "${PROJECT_NAME}"
)

# Tests
cmake_dependent_option(SOFA_COMPONENT_MYMODULE_BUILD_TESTS "Compile the automatic tests" ON
    "SOFA_BUILD_TESTS OR NOT DEFINED SOFA_BUILD_TESTS" OFF)
if(SOFA_COMPONENT_MYMODULE_BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()
```

### Key SOFA CMake Macros

Defined in `Sofa/framework/Config/cmake/` and loaded via `SofaMacros.cmake`:

- **`sofa_find_package(name [REQUIRED] [QUIET] [COMPONENTS ...])`** — wraps `find_package()`, checks if target already exists, and sets `${PROJECT_NAME}_HAVE_<PACKAGE>` variables for `config.h.in`.
- **`sofa_create_package_with_targets(...)`** — main macro that creates Config.cmake, sets target properties (version, compile definitions, include dirs, RPATH), and installs everything. Called once per module.
- **`sofa_add_targets_to_package(...)`** — adds additional targets to an existing package.
- **`sofa_add_subdirectory_modules(VAR DIRECTORIES dir1 dir2 ...)`** — used by umbrella modules (e.g., `Sofa.Component.SolidMechanics`) to gather sub-module targets.
- **`sofa_fetch_dependency(...)`** — fetch external dependencies from Git at configure time.

### Plugin CMake Pattern

Plugins use `RELOCATABLE "plugins"` so they install as self-contained directories:

```cmake
sofa_create_package_with_targets(
    PACKAGE_NAME ${PROJECT_NAME}
    PACKAGE_VERSION ${PROJECT_VERSION}
    TARGETS ${PROJECT_NAME} AUTO_SET_TARGET_PROPERTIES
    INCLUDE_SOURCE_DIR "src"
    RELOCATABLE "plugins"
)
```

### Test CMakeLists.txt Pattern

```cmake
cmake_minimum_required(VERSION 3.22)
project(Sofa.Component.MyModule_test)

set(SOURCE_FILES
    MyComponent_test.cpp
)

add_executable(${PROJECT_NAME} ${SOURCE_FILES})
target_link_libraries(${PROJECT_NAME} Sofa.Testing Sofa.Component.MyModule)

add_test(NAME ${PROJECT_NAME} COMMAND ${PROJECT_NAME})
```

### config.h.in Pattern

Each module has a `config.h.in` that defines its API export macro:

```cpp
#pragma once
#include <sofa/config.h>
#include <sofa/config/sharedlibrary_defines.h>

#ifdef SOFA_BUILD_SOFA_COMPONENT_MYMODULE
#  define SOFA_TARGET @PROJECT_NAME@
#  define SOFA_COMPONENT_MYMODULE_API SOFA_EXPORT_DYNAMIC_LIBRARY
#else
#  define SOFA_COMPONENT_MYMODULE_API SOFA_IMPORT_DYNAMIC_LIBRARY
#endif

namespace sofa::component::mymodule
{
    constexpr const char* MODULE_NAME = "@PROJECT_NAME@";
    constexpr const char* MODULE_VERSION = "@PROJECT_VERSION@";
}
```

## Fetched Plugin Sources

Some plugins are not bundled in the repository but are fetched by CMake at configure time. Their sources land in `$BUILD_DIR/external_directories/fetched/`. Directories containing plugin source code satisfy **both** conditions:

1. The directory name contains `sofa` (case-insensitive).
2. The directory name does **not** end with `-temp` or `-build`.

These directories follow the same source layout and conventions as in-tree plugins under `applications/plugins/`.

## Running Tests

```bash
# Configure with tests
cmake --preset minimal -DSOFA_BUILD_TESTS=ON <source-dir>

# Run all tests
ctest --output-on-failure

# Run a specific test
ctest -R <TestName> -V
```

Tests live in `test/` or `tests/` subdirectories next to the source they test. Test executables are named `<Module>_test` (unit tests) or `<Module>_simutest` (simulation tests).

## Architecture

The codebase has three layers:

**1. Framework** (`Sofa/framework/`) — 12 core libraries, built in this dependency order:
- `Sofa.Config` → `Sofa.Type` → `Sofa.Helper` → `Sofa.LinearAlgebra` → `Sofa.DefaultType` → `Sofa.Core` → `Sofa.Simulation` → `Sofa.Testing`
- `Sofa.Framework` is an umbrella target that links all framework libs.

**2. Components** (`Sofa/Component/`) — 21 independent modules (e.g., `ODESolver`, `LinearSolver`, `Collision`, `Mapping`, `Mass`, `SolidMechanics`). Each module can be toggled independently.

**3. Applications & Plugins** (`applications/`) — `runSofa` GUI, 40+ optional plugins (SofaPython3, MultiThreading, SofaGLFW, etc.).

## Core C++ Classes

### BaseObject (`sofa/core/objectmodel/BaseObject.h`)

Base class for all simulation components. Inherits from `virtual Base`.

**Key virtual methods:**
- `init()` — top-down initialization when the scene graph is built
- `bwdInit()` — bottom-up initialization (after all children are initialized)
- `reinit()` — called when Data values change and precomputed state must be refreshed
- `reset()` — reset component to its initial state
- `cleanup()` — called before destruction
- `storeResetState()` — save state for future `reset()` calls
- `draw(const VisualParams*)` — debug/visualization rendering
- `handleEvent(Event*)` — event processing callback
- `updateInternal()` — update internal cached variables

**Context access:** `getContext()` (const and non-const), `getTime()`.

### Data\<T\> (`sofa/core/objectmodel/Data.h`)

Serializable, GUI-visible component field. All persistent component state must be stored in `Data<T>` members.

**Declaration (class body, prefix `d_`):**
```cpp
Data<SReal> d_totalMass;
Data<bool> d_showObject;
Data<type::vector<Vec3>> d_positions;
```

**Initialization (constructor init list, using `initData`):**
```cpp
MyComponent::MyComponent()
    : d_totalMass(initData(&d_totalMass, SReal(1.0), "totalMass",
                           "Total mass of the object"))
    , d_showObject(initData(&d_showObject, false, "showObject",
                            "Display the object"))
{}
```

The `initData` arguments are: pointer to the data, default value, field name (used in scene files), and help string.

**Read/write access:**
```cpp
const auto& value = d_totalMass.getValue();   // Read (lazy eval if dirty)
d_totalMass.setValue(2.5);                     // Write (marks dependents dirty)

// Accessor helpers (RAII, preferred pattern)
auto read = sofa::helper::getReadAccessor(d_positions);
auto write = sofa::helper::getWriteAccessor(d_positions);
auto writeOnly = sofa::helper::getWriteOnlyAccessor(d_positions);
// Legacy: d_positions.beginEdit() / d_positions.endEdit()
```

### Link\<T\> (`sofa/core/objectmodel/Link.h`)

Typed dependency on another component. Declared with prefix `l_`.

```cpp
SingleLink<MyComponent, MechanicalState<DataTypes>,
           BaseLink::FLAG_STOREPATH | BaseLink::FLAG_STRONGLINK> l_mechanicalState;

// In constructor:
l_mechanicalState(initLink("mechanicalState",
                           "Link to the MechanicalState"))
```

### BaseContext (`sofa/core/objectmodel/BaseContext.h`)

Provides access to sibling components and context hierarchy.

```cpp
// Find a component by type in the scene graph
auto* mass = getContext()->get<BaseMass>();
auto* topo = getContext()->get<BaseMeshTopology>(BaseContext::SearchDirection::SearchUp);

// Get all components of a type
type::vector<ForceField<DataTypes>*> forceFields;
getContext()->get<ForceField<DataTypes>>(&forceFields, BaseContext::SearchDown);

// Context properties
SReal dt = getContext()->getDt();
const Vec3& gravity = getContext()->getGravity();
```

**SearchDirection values:** `Local`, `SearchUp` (default), `SearchDown`, `SearchRoot`, `SearchParents`.

### ForceField\<DataTypes\> (`sofa/core/behavior/ForceField.h`)

Base class for force computations. Inherits from `BaseForceField`.

**Key pure virtual methods:**
```cpp
void addForce(const MechanicalParams* mparams,
              DataVecDeriv& f, const DataVecCoord& x,
              const DataVecDeriv& v) = 0;

void addDForce(const MechanicalParams* mparams,
               DataVecDeriv& df, const DataVecDeriv& dx) = 0;

SReal getPotentialEnergy(const MechanicalParams* mparams,
                         const DataVecCoord& x) const = 0;
```

**Optional matrix assembly:**
```cpp
void addKToMatrix(BaseMatrix* matrix, SReal kFact, unsigned int& offset);
void addBToMatrix(BaseMatrix* matrix, SReal bFact, unsigned int& offset);
```

### Mass\<DataTypes\> (`sofa/core/behavior/Mass.h`)

Base class for mass computations. Inherits from `ForceField<DataTypes>` and `BaseMass`.

**Key methods:**
```cpp
void addMDx(const MechanicalParams*, DataVecDeriv& f,
            const DataVecDeriv& dx, SReal factor);
void accFromF(const MechanicalParams*, DataVecDeriv& a,
              const DataVecDeriv& f);
SReal getKineticEnergy(const MechanicalParams*, const DataVecDeriv& v) const;
void addMToMatrix(BaseMatrix* matrix, SReal mFact, unsigned int& offset);
```

### SOFA_CLASS Macro (`sofa/core/objectmodel/BaseClass.h`)

Every component must declare its type hierarchy using `SOFA_CLASS`:

```cpp
// Simple inheritance
SOFA_CLASS(MyComponent, BaseObject);

// Templated classes
SOFA_CLASS(SOFA_TEMPLATE(MyForceField, DataTypes),
           SOFA_TEMPLATE(core::behavior::ForceField, DataTypes));

// Multiple inheritance
SOFA_CLASS2(MyComponent, Parent1, Parent2);
```

This generates `GetClass()`, `getClass()`, `MyType`, `Inherit1` typedefs, etc.

### Common DataTypes Typedefs

Templated components typically define these at the top of the class:

```cpp
typedef TDataTypes DataTypes;
typedef typename DataTypes::Real Real;
typedef typename DataTypes::Coord Coord;
typedef typename DataTypes::Deriv Deriv;
typedef typename DataTypes::VecCoord VecCoord;
typedef typename DataTypes::VecDeriv VecDeriv;
typedef core::objectmodel::Data<VecCoord> DataVecCoord;
typedef core::objectmodel::Data<VecDeriv> DataVecDeriv;
```

Standard template parameters: `Vec3Types`, `Vec2Types`, `Vec1Types`, `Vec6Types`, `Rigid3Types`, `Rigid2Types`.

## C++ Coding Patterns

### Template Instantiation (h / inl / cpp)

SOFA uses explicit template instantiation to reduce compile times:

**Header (.h)** — declares the class template and `extern template` at the bottom:
```cpp
#pragma once
#include <sofa/component/mymodule/config.h>
// ...

namespace sofa::component::mymodule
{

template <class DataTypes>
class MyComponent : public core::behavior::ForceField<DataTypes>
{
public:
    SOFA_CLASS(SOFA_TEMPLATE(MyComponent, DataTypes),
               SOFA_TEMPLATE(core::behavior::ForceField, DataTypes));
    // ... declarations ...
};

#if !defined(SOFA_COMPONENT_MYMODULE_MYCOMPONENT_CPP)
extern template class SOFA_COMPONENT_MYMODULE_API MyComponent<defaulttype::Vec3Types>;
extern template class SOFA_COMPONENT_MYMODULE_API MyComponent<defaulttype::Vec2Types>;
#endif

} // namespace sofa::component::mymodule
```

**Implementation (.inl)** — template method definitions:
```cpp
#pragma once
#include <sofa/component/mymodule/MyComponent.h>

namespace sofa::component::mymodule
{

template <class DataTypes>
MyComponent<DataTypes>::MyComponent()
    : d_myField(initData(&d_myField, Real(0), "myField", "Description"))
{
}

template <class DataTypes>
void MyComponent<DataTypes>::addForce(/* ... */)
{
    // Implementation
}

} // namespace sofa::component::mymodule
```

**Explicit instantiation (.cpp)** — includes .inl, instantiates templates, and registers with factory:
```cpp
#define SOFA_COMPONENT_MYMODULE_MYCOMPONENT_CPP
#include <sofa/component/mymodule/MyComponent.inl>
#include <sofa/core/ObjectFactory.h>

namespace sofa::component::mymodule
{

void registerMyComponent(sofa::core::ObjectFactory* factory)
{
    factory->registerObjects(
        core::ObjectRegistrationData("Description of what this component does.")
        .add< MyComponent<defaulttype::Vec3Types> >()
        .add< MyComponent<defaulttype::Vec2Types> >()
    );
}

template class SOFA_COMPONENT_MYMODULE_API MyComponent<defaulttype::Vec3Types>;
template class SOFA_COMPONENT_MYMODULE_API MyComponent<defaulttype::Vec2Types>;

} // namespace sofa::component::mymodule
```

### Module init.cpp Pattern

Each module has an `init.cpp` that declares and calls all registration functions:

```cpp
#include <sofa/component/mymodule/init.h>
#include <sofa/core/ObjectFactory.h>
#include <sofa/helper/system/PluginManager.h>

namespace sofa::component::mymodule
{

extern void registerMyComponent(sofa::core::ObjectFactory* factory);
extern void registerOtherComponent(sofa::core::ObjectFactory* factory);

// extern "C" exports: initExternalModule() calls init(), getModuleName/Version() return MODULE_NAME/MODULE_VERSION

void registerObjects(sofa::core::ObjectFactory* factory)
{
    registerMyComponent(factory);
    registerOtherComponent(factory);
}

void init()
{
    static bool first = true;
    if (first)
    {
        sofa::helper::system::PluginManager::getInstance().registerPlugin(MODULE_NAME);
        first = false;
    }
}

} // namespace sofa::component::mymodule
```

### Messaging API

Use the SOFA messaging macros (never raw `std::cout` or `std::cerr`):

```cpp
msg_info(this) << "Informational message: value=" << value;
msg_warning(this) << "Potential issue detected";
msg_error(this) << "Something failed: " << errorCode;
msg_fatal(this) << "Unrecoverable error";

// msg_info only prints when the component's printLog flag is ON
// msg_warning / msg_error always print
// Conditional variants:
msg_info_when(condition, this) << "Only if condition is true";
msg_warning_when(verbosity > 2) << "Extra warnings";
```

### SOFA-Specific C++ Rules

- Use `sofa::type::vector<T>` instead of `std::vector<T>` (defined in `sofa/type/vector.h`).
- Avoid magic numbers; use `std::numeric_limits<DataTypes::Real>::epsilon()` for epsilon values.
- Use `const` profusely. Initialize variables at declaration.
- Minimize `#include` directives; prefer forward declarations in headers.
- Never use `using namespace` in header files (`.h` and `.inl`).
- Use `auto` only in for loops, iterators, and long/obvious typenames.
- Prefer explicit `Link<T>` over `getContext()->get<T>()` for inter-component dependencies.
- Use `sofa::simulation::Node` unless you specifically need tree access (`GNode`).
- All internal component state that must be saved or displayed in the GUI must be stored in `Data<T>`.
- Comments must be Doxygen-compliant: `///` before, `///<` after member declarations.

## Code Conventions

From `GUIDELINES.md`:

| Element | Convention |
|---|---|
| Classes | `UpperCamelCase` |
| Functions | `lowerCamelCase()` |
| Namespaces | `lowercase` (e.g., `sofa::core::behavior`) |
| `Data<T>` members | `d_name` prefix |
| `Link` members | `l_name` prefix |
| Other members | `m_name` prefix |
| Boolean members | Must answer a question: `m_isActive`, `m_hasName` |
| Files | One class per file, filename = class name, extensions `.h`/`.cpp`/`.inl` |

Formatting: 4-space indentation, Allman brace style, 100-char line limit. See `.clang-format` for auto-formatting. Never use tabs or indent inside namespaces.

## Commit Message Format

```
[ModuleName] ACTION short description

Examples:
[Sofa.Component.Mass] FIX incorrect calculation in DiagonalMass
[SofaKernel] ADD test for mass conservation in UniformMass
```

Actions: `ADD`, `REMOVE`, `FIX`, `CLEAN`, `REVERT`.

## Writing New Components

1. Inherit from the appropriate base class (`BaseObject`, `ForceField<DataTypes>`, `Mass<DataTypes>`, `MechanicalState<DataTypes>`, etc.).
2. Add `SOFA_CLASS(...)` at the top of the class body.
3. Declare state as `Data<T>` with `d_` prefix (automatically serializable and editable in GUI).
4. Initialize all `Data` members in the constructor using `initData(&d_field, default, "name", "help")`.
5. Use `Link<T>` with `l_` prefix for dependencies on other components (initialized with `initLink`).
6. Implement required virtual methods (`init()`, `addForce()`, etc.).
7. Create the `.h` / `.inl` / `.cpp` file triplet with the extern template / explicit instantiation pattern.
8. Write a `registerMyComponent(ObjectFactory*)` function in the `.cpp` file.
9. Declare and call that function from the module's `init.cpp`.
10. Add a test in the module's `test/` directory inheriting from `sofa::testing::BaseTest`.
11. Template on `DataTypes` (typically `Vec3Types`, `Rigid3Types`) for generic simulation types.
