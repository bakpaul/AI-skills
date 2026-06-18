// main.cpp - FetchContent example

#include <fmt/core.h>
#include <nlohmann/json.hpp>
#include <iostream>

int main() {
    // Use fmt library
    fmt::print("Hello from fmt library!\n");
    fmt::print("Formatted number: {:.2f}\n", 3.14159);
    
    // Use nlohmann/json library
    nlohmann::json j;
    j["name"] = "FetchContent Example";
    j["version"] = "1.0.0";
    j["dependencies"] = {"fmt", "nlohmann_json"};
    
    std::cout << "\nJSON output:\n";
    std::cout << j.dump(2) << std::endl;
    
    return 0;
}
