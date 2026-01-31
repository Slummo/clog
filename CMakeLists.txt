cmake_minimum_required(VERSION 4.0)
project(clog VERSION 1.0.0 LANGUAGES C)

# Create static library
add_library(clog INTERFACE)
target_include_directories(clog INTERFACE include)
add_library(clog::core ALIAS clog)

# Create examples
if (CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME)
    add_executable(example1)
    target_include_directories(example1 PRIVATE include)
    target_sources(example1 PRIVATE examples/example1.c)
endif()