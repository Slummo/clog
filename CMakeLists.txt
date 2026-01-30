cmake_minimum_required(VERSION 4.0)
project(clog VERSION 1.0.0 LANGUAGES C)

add_library(clog STATIC src/log/log.c)
target_include_directories(clog PUBLIC include)