#
# Copyright 2021-2025 Software Radio Systems Limited
#
# This file is part of srsRAN-matlab.
#
# srsRAN-matlab is free software: you can redistribute it and/or
# modify it under the terms of the BSD 2-Clause License.
#
# srsRAN-matlab is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# BSD 2-Clause License for more details.
#
# A copy of the BSD 2-Clause License can be found in the LICENSE
# file in the top-level directory of this distribution.
#

########################################################################
# Prevent in-tree builds
########################################################################
if(${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_BINARY_DIR})
    message(FATAL_ERROR "Prevented in-tree build. This is bad practice.")
endif(${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_BINARY_DIR})

########################################################################
# Project setup
########################################################################
cmake_minimum_required(VERSION 3.14)
project(srsRAN-matlab VERSION 0.1)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wl,--exclude-libs,ALL")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
    message(STATUS "Build type not specified: defaulting to Release.")
endif(NOT CMAKE_BUILD_TYPE)
set(CMAKE_BUILD_TYPE ${CMAKE_BUILD_TYPE} CACHE STRING "Build type" FORCE)
set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release")

########################################################################
# Options
########################################################################

option(ASSERTS_ENABLED "Enable srsRAN asserts" ON)

if (ASSERTS_ENABLED)
    add_definitions(-DASSERTS_ENABLED)
endif()

########################################################################
# Compiler specific setup
########################################################################
macro(ADD_CXX_COMPILER_FLAG_IF_AVAILABLE flag have)
    include(CheckCXXCompilerFlag)
    check_cxx_compiler_flag(${flag} ${have})
    if (${have})
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${flag}")
    endif (${have})
endmacro(ADD_CXX_COMPILER_FLAG_IF_AVAILABLE)

# Make sure no instance of abstract class is left without a destructor
ADD_CXX_COMPILER_FLAG_IF_AVAILABLE(-Wnon-virtual-dtor HAVE_NON_VIRTUAL_DTOR)

# Make sure all overridden methods are marked as override
ADD_CXX_COMPILER_FLAG_IF_AVAILABLE(-Wsuggest-override HAVE_SUGGEST_OVERRIDE)

if(${CMAKE_BUILD_TYPE} STREQUAL "Debug")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ggdb -O0 -DDEBUG_MODE -DBUILD_TYPE_DEBUG")
endif(${CMAKE_BUILD_TYPE} STREQUAL "Debug")

########################################################################
# Requirements
########################################################################
# MATLAB
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/modules")

find_package(Matlab REQUIRED)

find_package(SRSRAN MODULE REQUIRED)

include(${SRSRAN_BINARY_DIR}/srsran.cmake)
include_directories(
    ${CMAKE_SOURCE_DIR}/include
    ${SRSRAN_INCLUDE_DIR}
    ${SRSRAN_SOURCE_DIR}/external/fmt/include
    ${SRSRAN_SOURCE_DIR}/external
)

add_subdirectory(lib)
add_subdirectory(unittests)
add_subdirectory(docs)
