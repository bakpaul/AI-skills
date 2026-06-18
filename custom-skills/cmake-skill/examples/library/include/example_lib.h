// example_lib.h - Example library public header

#ifndef EXAMPLE_LIB_H
#define EXAMPLE_LIB_H

#include <string>

namespace example {

// Get library version
std::string get_version();

// Simple addition function
int add(int a, int b);

} // namespace example

#endif // EXAMPLE_LIB_H
