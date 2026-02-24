Add fetched SOFA plugin source directories from a SOFA build tree to the current working context.

Build directory provided: $ARGUMENTS

Fetched SOFA plugin source directories found:
!`find "$ARGUMENTS/external_directories/fetched" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | while read d; do name=$(basename "$d"); lower=$(echo "$name" | tr '[:upper:]' '[:lower:]'); case "$lower" in *sofa*) ;; *) continue ;; esac; case "$name" in *-temp|*-build) continue ;; esac; echo "$d"; done`

Instructions:
- If "$ARGUMENTS" is empty or no directories were listed above, ask the user to provide the build directory path and re-run as: `/sofa-add-fetched <build-dir>`
- If directories are listed, for each one:
  1. Read its top-level `CMakeLists.txt` to understand what plugin it provides and how it is structured.
  2. Briefly report its name and purpose to the user.
- After processing all directories, confirm to the user which plugin sources are now part of your working context and available for navigation, search, and editing in this session.
