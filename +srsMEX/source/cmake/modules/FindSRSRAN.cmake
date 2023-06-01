#
# Copyright 2021-2023 Software Radio Systems Limited
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

#[=======================================================================[.rst:
FindSRSRAN
-------

Finds the SRSRAN exported libraries.

Imported Targets
^^^^^^^^^^^^^^^^

This module provides access to the targets exported by SRSRAN. They will be
available under the namespace ``srsran::``.


Result Variables
^^^^^^^^^^^^^^^^

This will define the following variables:

``SRSRAN_FOUND``
  True if the SRSRAN libraries were found.
``SRSRAN_SOURCE_DIR``
  Root source directory of SRSRAN.
``SRSRAN_INCLUDE_DIR``
  Include directory needed to use SRSRAN.
``SRSRAN_BINARY_DIR``
  Full path to the top level of the SRSRAN build tree.

Cache Variables
^^^^^^^^^^^^^^^

The following cache variables may also be set:

``SRSRAN_BINARY_DIR``
  Full path to the top level of the SRSRAN build tree.

#]=======================================================================]

file(GLOB SRSRAN_PATH LIST_DIRECTORIES true "$ENV{HOME}/srsRAN_Project" "$ENV{HOME}/*/srsRAN_Project" "$ENV{HOME}/*/*/srsRAN_Project")
message(STATUS "srsran possible paths: ${SRSRAN_PATH}.")

set(SRSRAN_PATH_BUILD ${SRSRAN_PATH})
list(TRANSFORM SRSRAN_PATH_BUILD APPEND "/build")

set(SRSRAN_PATH_BUILD_STAR ${SRSRAN_PATH})
list(TRANSFORM SRSRAN_PATH_BUILD_STAR APPEND "/build*")
file(GLOB SRSRAN_PATH_BUILD_STAR LIST_DIRECTORIES true ${SRSRAN_PATH_BUILD_STAR})

set(SRSRAN_PATH_CMAKE_BUILD ${SRSRAN_PATH})
list(TRANSFORM SRSRAN_PATH_CMAKE_BUILD APPEND "/cmake-build-*")
file(GLOB SRSRAN_PATH_CMAKE_BUILD LIST_DIRECTORIES true ${SRSRAN_PATH_CMAKE_BUILD})

find_path(SRSRAN_BINARY_DIR srsran.cmake
    HINTS ${SRSRAN_PATH_BUILD} ${SRSRAN_PATH_BUILD_STAR} ${SRSRAN_PATH_CMAKE_BUILD}
    NO_DEFAULT_PATH
)

if (SRSRAN_BINARY_DIR)
    get_filename_component(SRSRAN_SOURCE_DIR ${SRSRAN_BINARY_DIR} DIRECTORY)
    set(SRSRAN_INCLUDE_DIR ${SRSRAN_SOURCE_DIR}/include)
endif (SRSRAN_BINARY_DIR)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SRSRAN
    FOUND_VAR SRSRAN_FOUND
    REQUIRED_VARS
        SRSRAN_SOURCE_DIR
        SRSRAN_INCLUDE_DIR
        SRSRAN_BINARY_DIR
)
