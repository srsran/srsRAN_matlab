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

find_package(Doxygen OPTIONAL_COMPONENTS dot)

if (DOXYGEN_FOUND)
  # Configure doxygen
  set(DOXYGEN_PROJECT_NUMBER ${VERSION})
  set(DOXYGEN_PROJECT_LOGO ${CMAKE_CURRENT_SOURCE_DIR}/srsRAN_project_logo.png)
  set(DOXYGEN_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
  set(DOXYGEN_WARN_LOGFILE ${CMAKE_CURRENT_BINARY_DIR}/doxygen.log)
  set(DOXYGEN_USE_MATHJAX "YES")
  set(DOXYGEN_MATHJAX_EXTENSIONS "TeX/AMSmath")
  set(DOXYGEN_FORMULA_MACROFILE ${CMAKE_CURRENT_SOURCE_DIR}/math_macros.tex)
  set(DOXYGEN_STRIP_FROM_PATH ${CMAKE_HOME_DIRECTORY})
  set(DOXYGEN_EXTRACT_STATIC "YES")
  set(DOXYGEN_EXTRACT_PRIVATE "YES")
  set(DOXYGEN_GENERATE_TREEVIEW "YES")
  set(DOXYGEN_HTML_HEADER "header.html")
  if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/doxygen-awesome.css)
    set(DOXYGEN_GENERATE_TREEVIEW "YES")
    set(DOXYGEN_HTML_EXTRA_STYLESHEET "doxygen-awesome.css")
  endif()
  set(DOXYGEN_UML_LOOK "YES")
  set(DOXYGEN_CALL_GRAPH "YES")
  set(DOXYGEN_CALLER_GRAPH "YES")
  set(DOXYGEN_DISTRIBUTE_GROUP_DOC "YES")

  # find plantuml
  find_program(PLANTUML_PATH plantuml.jar PATH_SUFFIXES PlantUML plantuml Plantuml
          PATHS /usr/share /usr/local/share /usr/local/bin /opt/local/share/java)
  if (PLANTUML_PATH)
    message(STATUS "PLANTUML found in ${PLANTUML_PATH}.")
  endif ()
  set(DOXYGEN_PLANTUML_JAR_PATH "${PLANTUML_PATH}")

  # directories and files to process for all the docs
  set(docs_inputs ${CMAKE_CURRENT_SOURCE_DIR}
                  ${CMAKE_HOME_DIRECTORY}/include/srsran_matlab
                  ${CMAKE_HOME_DIRECTORY}/lib
                  ${CMAKE_HOME_DIRECTORY}/unittests
  )

  doxygen_add_docs(doxygen
    ${docs_inputs}
    COMMENT "Generating all documentation."
  )

  add_custom_target(doxygen-clean
    COMMAND ${CMAKE_COMMAND} -E rm -rf ${CMAKE_CURRENT_BINARY_DIR}/html
                                       ${CMAKE_CURRENT_BINARY_DIR}/doxygen.log
    COMMENT "Cleaning documentation"
    VERBATIM
  )
endif(DOXYGEN_FOUND)
