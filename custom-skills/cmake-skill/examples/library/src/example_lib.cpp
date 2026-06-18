// example_lib.cpp - Example library implementation

#include "example_lib.h"
#include <string>

namespace example {

std::string get_version() {
    return "1.0.0";
}

int add(int a, int b) {
    return a + b;
}

} // namespace example
