---
name: sofa-compat-layer
description: Analyzes the diff between the current branch and master in a SOFA repository and adds the appropriate backward-compatibility layer (compat headers, DeprecatedData/RemovedData/RenamedData, ComponentChange registry entries) for any breaking changes found.
---

# SOFA Compatibility Layer Skill

You are helping a SOFA framework developer add backward-compatibility scaffolding after a breaking change. The developer has already made their change on the current branch. Your job is to inspect what changed, identify what compat work is needed, and implement it.

## Quick-reference: includes required per pattern

| Pattern | Header to `#include` |
|---|---|
| A — compat stub | `<sofa/config.h>` (provides `SOFA_HEADER_DEPRECATED` / `SOFA_HEADER_DISABLED`) |
| B — `using` alias | `<sofa/config.h>` (provides `SOFA_ATTRIBUTE_DEPRECATED`) |
| C — forwarding method | `<sofa/config.h>` (provides `SOFA_ATTRIBUTE_DEPRECATED`) |
| D — `RenamedData` | `<sofa/core/objectmodel/lifecycle/RenamedData.h>` |
| E — `RemovedData` | `<sofa/core/objectmodel/lifecycle/RemovedData.h>` |
| F — `DeprecatedData` | `<sofa/core/objectmodel/lifecycle/DeprecatedData.h>` |
| G — `ComponentChange.cpp` | No extra include — `ComponentChange.h` is already included |

---

## Step 1 — Understand the diff

Run:
```bash
git diff master...HEAD --name-status
git diff master...HEAD -- '*.h' '*.cpp' '*.cmake' 'CMakeLists.txt'
```

To isolate specific change types, use `--diff-filter`:
```bash
# Renamed or moved headers
git diff master...HEAD --name-status --diff-filter=R -- '*.h'
# Deleted headers
git diff master...HEAD --name-status --diff-filter=D -- '*.h'
# Modified public headers (method/Data changes)
git diff master...HEAD --diff-filter=M -- '*.h'
```

From the diff, identify every breaking change that external users of SOFA could be affected by:

- **Header moved or renamed**: a `.h` file changed path
- **Class or component renamed**: class name changed in a header
- **Data field renamed or removed**: a `Data<T>` member was renamed or deleted from a component
- **Component moved to another module or plugin**: `CMakeLists.txt` or directory structure changed
- **Public API function renamed or removed**: a public method signature changed or disappeared

### What NOT to flag

Do not add compat scaffolding for:
- Members in `private:` or `protected:` sections
- Symbols inside `namespace detail`, `namespace impl`, or anonymous namespaces
- `.cpp`-only changes (internal implementation, not visible API)
- Files under `test/` or `simutest/` directories
- Comment-only or include-guard-only changes
- Forward declarations
- `config.h.in` version string bumps

### Determine the version strings

Read `Sofa_VERSION_MAJOR` and `Sofa_VERSION_MINOR` from the root `CMakeLists.txt`:
```bash
grep -E "Sofa_VERSION_(MAJOR|MINOR)" CMakeLists.txt
```

The patch value is always `99` during development — ignore it. Build the two version strings:

- **Deprecation version** (`SINCE`): `v<MAJOR>.<MINOR>` — the current development version, i.e. the release in which this compat layer ships.
- **Removal version** (`UNTIL`): `v<MAJOR+1>.<MINOR>` — one full year later (same month, next year), which is two releases away. This is the standard window for breaking changes.

Example: if `Sofa_VERSION_MAJOR=26` and `Sofa_VERSION_MINOR=06`, then `SINCE=v26.06` and `UNTIL=v27.06`.

For each breaking change, note:
- The old path / name / signature
- The new path / name / signature
- The module it belongs to (e.g. `Sofa.Component.Collision.Geometry`, `Sofa.Simulation.Core`)
- The computed `SINCE` and `UNTIL` version strings

### Summary table and user confirmation

Use this mapping to assign the right pattern to each change:

| What changed | Pattern |
|---|---|
| Header file moved to a new path | A — compat folder stub |
| Class or type alias renamed | B — deprecated `using` alias |
| Public method or free function renamed | C — deprecated forwarding method |
| `Data<T>` field renamed | D — `RenamedData<T>` |
| `Data<T>` field removed | E — `RemovedData` |
| `Data<T>` field deprecated but kept | F — `DeprecatedData` |
| Component class renamed, moved, deprecated, or removed | G — `ComponentChange.cpp` registry |

Then present all identified changes as a compact table before doing any work:

| # | What changed | Old name / path | New name / path | Pattern | File(s) to modify |
|---|---|---|---|---|---|
| 1 | Header moved | `sofa/old/Foo.h` | `sofa/new/Foo.h` | A | `MyModule/compat/`, `CMakeLists.txt` |
| 2 | Class renamed | `OldName` | `NewName` | B | `sofa/new/NewName.h` |
| … | … | … | … | … | … |

State the computed version strings (`SINCE` and `UNTIL`) and ask:

> "Does this look correct? Let me know if you want to skip or adjust any of these before I proceed."

Wait for the user's reply. If they exclude or modify entries, update your working list accordingly before moving to Step 2.

---

## Step 2 — Apply the confirmed compat patterns

For each confirmed entry, apply the pattern using the reference below.

---

### Pattern A — Compat folder stub (header moved)

**When**: a header changed path and external code `#include`s the old path.

#### File layout

Create `<module>/compat/<old-include-path>.h` — the directory tree under `compat/` must reproduce the old include path exactly.

Example: header moved from `sofa/component/old/Foo.h` to `sofa/component/new/Foo.h` in module `MyModule`:

```
MyModule/
  compat/
    sofa/
      component/
        old/
          Foo.h        ← the stub
  src/
    sofa/
      component/
        new/
          Foo.h        ← the new location
```

#### Content of the stub

```cpp
#pragma once
#include <sofa/component/new/Foo.h>
SOFA_HEADER_DEPRECATED("v26.06", "v27.06", "sofa/component/new/Foo.h")
```

Use `SOFA_HEADER_DISABLED` instead of `SOFA_HEADER_DEPRECATED` if the header was broken some time ago and has already been disabled (i.e., the change is not fresh in this release).

If the class namespace also changed, add a `using` alias in the stub (see Pattern A+B combined below):
```cpp
#pragma once
#include <sofa/component/new/Foo.h>
SOFA_HEADER_DEPRECATED("v26.06", "v27.06", "sofa/component/new/Foo.h")

namespace sofa::component::old
{
using Foo SOFA_ATTRIBUTE_DEPRECATED("v26.06", "v27.06",
    "sofa::component::old::Foo has been moved to sofa::component::new::Foo")
    = sofa::component::new_ns::Foo;
} // namespace sofa::component::old
```

#### Wire the compat folder in CMakeLists.txt

Set a variable for the deprecated headers, add them to `target_include_directories`, and install the directory:

```cmake
set(DEPRECATED_DIR "compat/MyModule")
set(DEPRECATED_HEADER_FILES
    ${DEPRECATED_DIR}/sofa/component/old/Foo.h
)

# ... existing add_library / sofa_add_library call ...

target_include_directories(${PROJECT_NAME} PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/compat>
    $<INSTALL_INTERFACE:include/${PROJECT_NAME}_compat>
)

install(DIRECTORY compat/ DESTINATION include/${PROJECT_NAME}_compat COMPONENT headers)
```

If `target_include_directories` already exists in the file, add the two compat entries to the existing block — do not create a duplicate call. If a `DEPRECATED_HEADER_FILES` variable already exists, append to it.

Note: `DEPRECATED_HEADER_FILES` is declared for IDE indexing purposes only (so IDEs show the compat headers in the project tree). It is **not** passed to `install()` — the `install(DIRECTORY compat/ ...)` call handles installation of the whole directory.

---

### Pattern B — Deprecated `using` alias (class or type renamed)

**When**: a class or type alias was renamed, but the old name should still compile with a warning.

In the header where the new name is defined, add after the new class definition and **inside the old namespace**:

```cpp
namespace sofa::component::old_ns  // ← must match the old name's namespace
{
using OldName SOFA_ATTRIBUTE_DEPRECATED("v26.06", "v27.06",
    "OldName has been renamed to sofa::component::new_ns::NewName")
    = sofa::component::new_ns::NewName;
} // namespace sofa::component::old_ns
```

If old and new namespaces are the same, you can add the alias directly at the end of the same namespace block where the new class is defined.

For a templated class:
```cpp
namespace sofa::component::old_ns
{
template<class DataTypes>
using OldName SOFA_ATTRIBUTE_DEPRECATED("v26.06", "v27.06",
    "OldName has been renamed to sofa::component::new_ns::NewName")
    = sofa::component::new_ns::NewName<DataTypes>;
} // namespace sofa::component::old_ns
```

Real examples from the codebase:
```cpp
// sofa/core/behavior/Constraint.h
using Constraint SOFA_ATTRIBUTE_DEPRECATED("v25.12", "v26.12",
    "Constraint has been renamed to LagrangianConstraint")
    = LagrangianConstraint<DataTypes>;

// sofa/geometry/Prism.h
using Pentahedron SOFA_ATTRIBUTE_DEPRECATED("v25.12", "v26.06",
    "Pentahedron is renamed to Prism") = Prism;
```

`SOFA_ATTRIBUTE_DEPRECATED` is defined in `<sofa/config.h>`.

---

### Pattern C — Deprecated forwarding method (public method or free function renamed)

**When**: a public C++ method or free function was renamed, but the old name should still compile with a warning.

In the `public:` section of the header, keep the old name as a deprecated inline forwarder:

```cpp
SOFA_ATTRIBUTE_DEPRECATED("<SINCE>", "<UNTIL>", "Use newMethodName() instead.")
ReturnType oldMethodName(Args... args) { return newMethodName(args...); }
```

For a `const` method, the forwarder must also be `const`:
```cpp
SOFA_ATTRIBUTE_DEPRECATED("<SINCE>", "<UNTIL>", "Use newMethodName() instead.")
ReturnType oldMethodName(Args... args) const { return newMethodName(args...); }
```

For a method with default arguments, **always repeat the default values** in the forwarder signature:
```cpp
// Old: void foo(int x, bool flag = false);
// New: void bar(int x, bool flag = false);
SOFA_ATTRIBUTE_DEPRECATED("<SINCE>", "<UNTIL>", "Use bar() instead.")
void foo(int x, bool flag = false) { bar(x, flag); }
```

If the method was removed with no direct replacement (behavior deleted or merged elsewhere), keep the original implementation inline instead of forwarding:
```cpp
SOFA_ATTRIBUTE_DEPRECATED("<SINCE>", "<UNTIL>", "This method no longer has a replacement.")
ReturnType oldMethodName(Args... args) { /* original implementation */ }
```

---

### Pattern D — RenamedData (Data field renamed, still functional)

**When**: a `Data<T>` field was renamed but the old name should still be readable from XML scenes.

**Important**: the `RenamedData<T>` member must use **the exact same symbol** as the original `Data<T>` field — including any prefix (e.g., declare it `d_oldName` if the original was `d_oldName`, or `proximity` if the original was `proximity`). This is a compat shim, not a real `Data<>`, so it does not need to be registered like a `Data<>`.

In the component header, add next to the new field:
```cpp
#include <sofa/core/objectmodel/lifecycle/RenamedData.h>

class MyComponent : public BaseObject
{
public:
    Data<SReal> d_newName;
    sofa::core::objectmodel::lifecycle::RenamedData<SReal> d_oldName;  // same symbol as original
    // ...
};
```

In the constructor **body** (not the initializer list — `RenamedData` has a default constructor), wire the shim to the real field and register the alias. The string passed to `addAlias` must be the **XML attribute name** of the original field, which you find by inspecting the `initData` call for that field in the constructor:

- `initData(&d_field, "xmlName", "help")` → 2 strings, XML name is the **first** (`"xmlName"`)
- `initData(&d_field, "defaultValue", "xmlName", "help")` → 3 strings, XML name is the **second** (`"xmlName"`)

```cpp
MyComponent::MyComponent()
    : d_newName(initData(&d_newName, SReal(0), "newName", "Description"))
{
    d_oldName.setOriginalData(&d_newName);
    this->addAlias(&d_newName, "oldName");  // "oldName" = the XML name from the original initData call
}
```

Real example from `CollisionModel`:
```cpp
// CollisionModel.h
objectmodel::lifecycle::RenamedData<SReal> proximity;  // old symbol, no d_ prefix

// CollisionModel.cpp constructor body
proximity.setOriginalData(&d_contactDistance);
this->addAlias(&d_contactDistance, "proximity");
```

---

### Pattern E — RemovedData (Data field deleted)

**When**: a `Data<T>` field was removed entirely and should produce an error if a scene tries to set it.

**Important**: the member symbol must match the original `Data<T>` symbol exactly (same name, same prefix).

Declare as an in-class member initializer in the header using brace-initialization:
```cpp
#include <sofa/core/objectmodel/lifecycle/RemovedData.h>

class MyComponent : public BaseObject
{
public:
    // ...
    sofa::core::objectmodel::lifecycle::RemovedData d_oldName
        {this, "<SINCE>", "<UNTIL>", "oldName", "Explanation of what to use instead."};
};
```

No constructor or `init()` changes are needed — the `RemovedData` constructor registers itself with the owning `Base` object automatically. `Base::parse()` will emit `msg_error()` when a scene sets this attribute.

Real example from `OglLabel` (note: the `"23.12"` in the source is a codebase typo — the canonical format always includes the `v` prefix):
```cpp
core::objectmodel::lifecycle::RemovedData d_visible
    {this, "v23.06", "v23.12", "visible", "Use the 'enable' data field instead of 'visible'"};
```

---

### Pattern F — DeprecatedData (Data field kept but discouraged)

**When**: a `Data<T>` field is still functional but should be replaced.

**Important**: the member symbol must match the original `Data<T>` symbol exactly (same name, same prefix).

```cpp
#include <sofa/core/objectmodel/lifecycle/DeprecatedData.h>

class MyComponent : public BaseObject
{
public:
    // ...
    sofa::core::objectmodel::lifecycle::DeprecatedData d_oldName
        {this, "<SINCE>", "<UNTIL>", "oldName", "Use d_newName instead."};
};
```

No constructor or `init()` changes are needed. `Base::parse()` emits `msg_deprecated()` on access.

---

### Pattern G — ComponentChange registry (component renamed/moved/deprecated/removed)

**When**: an entire component class was renamed, moved, deprecated, or removed.

Edit `Sofa/framework/Helper/src/sofa/helper/ComponentChange.cpp`. All required types (`Deprecated`, `Moved`, `Pluginized`, `Renamed`, `RemovedIn`, `Dealiased`) are already available via the existing `#include <sofa/helper/ComponentChange.h>` — no extra includes needed.

#### Registered component name = C++ class name

The map key is always the **C++ class name exactly as written** (e.g., class `EulerImplicitSolver` → key `"EulerImplicitSolver"`). No grep or lookup is needed.

#### Decision tree: which map and constructor to use

| Scenario | Map | Constructor |
|---|---|---|
| Still usable, will be removed in `<UNTIL>` | `deprecatedComponents` | `Deprecated("<SINCE>", "<UNTIL>", "message")` |
| Moved to a different SOFA module | `movedComponents` | `Moved("<SINCE>", "fromModule", "toModule")` |
| Moved to an external plugin | `movedComponents` | `Pluginized("<SINCE>", "PluginName")` |
| Renamed, old name still works until `<UNTIL>` | `renamedComponents` | `Renamed("<SINCE>", "<UNTIL>", "NewName")` |
| Fully removed after a prior deprecation | `uncreatableComponents` | `RemovedIn("<UNTIL>").afterDeprecationIn("<SINCE>")` |
| Fully removed with no prior deprecation | `uncreatableComponents` | `RemovedIn("<UNTIL>").withoutAnyDeprecation()` |
| Short alias removed, canonical name still works | `dealiasedComponents` | `Dealiased("<SINCE>", "CanonicalName")` |

#### Examples

```cpp
// std::map<std::string, Deprecated> — still usable, warns until removal
deprecatedComponents["ConstraintAnimationLoop"] =
    Deprecated("v26.06", "v26.12", "Use FreeMotionAnimationLoop instead.");

// std::map<std::string, ComponentChange> — moved to another module
movedComponents["EulerImplicitSolver"] =
    Moved("v22.06", "SofaImplicitOdeSolver", Sofa.Component.ODESolver.Backward);

// std::map<std::string, ComponentChange> — moved to an external plugin
movedComponents["Monitor"] = Pluginized("v20.06", "SofaValidation");

// std::map<std::string, Renamed> — old name auto-redirects to new, warns until <UNTIL>
renamedComponents["FixedConstraint"] =
    Renamed("v26.06", "v27.06", "FixedProjectiveConstraint");

// std::map<std::string, ComponentChange> — fully removed after prior deprecation
uncreatableComponents["MakeAliasComponent"] =
    RemovedIn("v27.06").afterDeprecationIn("v26.06");

// std::map<std::string, ComponentChange> — fully removed, never deprecated
uncreatableComponents["HexahedronSetTopologyAlgorithms"] =
    RemovedIn("v27.06").withoutAnyDeprecation();

// std::map<std::string, Dealiased> — short alias removed, canonical name still works
dealiasedComponents["MeshObjLoader"] = Dealiased("v26.06", "MeshOBJLoader");
```

The `ObjectFactory` consults these maps at scene load time and generates user-facing messages automatically.

---

### Combined: Pattern A + B (header moved AND class renamed)

When a header is moved **and** the class is also renamed or its namespace changes, handle both in the compat stub — do **not** add a separate Pattern B alias in the new header.

```cpp
// compat/sofa/component/old/OldName.h
#pragma once
#include <sofa/component/new/NewName.h>
SOFA_HEADER_DEPRECATED("v26.06", "v27.06", "sofa/component/new/NewName.h")

namespace sofa::component::old_ns
{
using OldName SOFA_ATTRIBUTE_DEPRECATED("v26.06", "v27.06",
    "sofa::component::old_ns::OldName has been renamed to sofa::component::new_ns::NewName")
    = sofa::component::new_ns::NewName;
} // namespace sofa::component::old_ns
```

The compat stub is the single source of truth for the old include path + old class name. The new header stays clean.

---

## Step 3 — Report what was done

After making all changes, provide a short summary:
- Which patterns were applied and to which files
- Any manual follow-up the developer should do (e.g., updating scene files in `examples/`, adding test coverage, bumping version strings)
