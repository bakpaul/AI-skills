// main.cpp - Example consumer application

#include <example_lib.h>
#include <iostream>

int main() {
    std::cout << "ExampleLib version: " << example::get_version() << std::endl;
    
    int result = example::add(5, 7);
    std::cout << "5 + 7 = " << result << std::endl;
    
    return 0;
}
