cmake_minimum_required(VERSION 4.0)
project(clog VERSION 1.0.0 LANGUAGES C)

# Create static library
set(CLOG_LIB ${PROJECT_NAME})
add_library(${CLOG_LIB} STATIC)
target_include_directories(${CLOG_LIB} PUBLIC include)
target_sources(${CLOG_LIB} PRIVATE src/log/log.c)

# Create examples
if (CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME)
    add_executable(example1)
    target_include_directories(example1 PRIVATE include)
    target_sources(example1 PRIVATE examples/example1.c)
    target_link_libraries(example1 PRIVATE ${CLOG_LIB})
endif()