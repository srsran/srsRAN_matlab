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

add_library(resource_grid SHARED resource_grid.cpp)
target_include_directories(resource_grid PUBLIC ${Matlab_INCLUDE_DIRS})
target_link_libraries(resource_grid
    PRIVATE srsran::srsran_channel_precoder
            srsran::srsran_signal_processors)
add_library(srsran_matlab::resource_grid ALIAS resource_grid)
