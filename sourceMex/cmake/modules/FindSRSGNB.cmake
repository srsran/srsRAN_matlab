# Missing license!

#[=======================================================================[.rst:
FindSRSGNB
-------

Finds the SRSGNB exported libraries.

Imported Targets
^^^^^^^^^^^^^^^^

This module provides access to the targets exported by SRSGNB. They will be
available under the namespace ``srsgnb::``.


Result Variables
^^^^^^^^^^^^^^^^

This will define the following variables:

``SRSGNB_FOUND``
  True if the SRSGNB libraries were found.
``SRSGNB_SOURCE_DIR``
  Root source directory of SRSGNB.
``SRSGNB_INCLUDE_DIR``
  Include directory needed to use SRSGNB.
``SRSGNB_BINARY_DIR``
  Full path to the top level of the SRSGNB build tree.

Cache Variables
^^^^^^^^^^^^^^^

The following cache variables may also be set:

``SRSGNB_BINARY_DIR``
  Full path to the top level of the SRSGNB build tree.

#]=======================================================================]

file(GLOB SRSGNB_PATH LIST_DIRECTORIES true "$ENV{HOME}/srsgnb*" "$ENV{HOME}/*/srsgnb*" "$ENV{HOME}/*/*/srsgnb*")
message(STATUS "srsgnb possible paths: ${SRSGNB_PATH}.")

set(SRSGNB_PATH_BUILD ${SRSGNB_PATH})
list(TRANSFORM SRSGNB_PATH_BUILD APPEND "/build")

set(SRSGNB_PATH_BUILD_STAR ${SRSGNB_PATH})
list(TRANSFORM SRSGNB_PATH_BUILD_STAR APPEND "/build*")
file(GLOB SRSGNB_PATH_BUILD_STAR LIST_DIRECTORIES true ${SRSGNB_PATH_BUILD_STAR})

set(SRSGNB_PATH_CMAKE_BUILD ${SRSGNB_PATH})
list(TRANSFORM SRSGNB_PATH_CMAKE_BUILD APPEND "/cmake-build-*")
file(GLOB SRSGNB_PATH_CMAKE_BUILD LIST_DIRECTORIES true ${SRSGNB_PATH_CMAKE_BUILD})

find_path(SRSGNB_BINARY_DIR srsgnb.cmake
    HINTS ${SRSGNB_PATH_BUILD} ${SRSGNB_PATH_BUILD_STAR} ${SRSGNB_PATH_CMAKE_BUILD}
    NO_DEFAULT_PATH
)

if (SRSGNB_BINARY_DIR)
    get_filename_component(SRSGNB_SOURCE_DIR ${SRSGNB_BINARY_DIR} DIRECTORY)
    set(SRSGNB_INCLUDE_DIR ${SRSGNB_SOURCE_DIR}/include)
endif (SRSGNB_BINARY_DIR)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SRSGNB
    FOUND_VAR SRSGNB_FOUND
    REQUIRED_VARS
        SRSGNB_SOURCE_DIR
        SRSGNB_INCLUDE_DIR
        SRSGNB_BINARY_DIR
)
