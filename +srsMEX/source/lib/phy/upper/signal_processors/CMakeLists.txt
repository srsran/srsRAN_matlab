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

matlab_add_mex(
    NAME multiport_channel_estimator_mex
    SRC multiport_channel_estimator_mex.cpp
    R2018a
)

target_link_libraries(multiport_channel_estimator_mex
    srsran_matlab::resource_grid
    srsran::srsran_channel_estimator
    srsran::srsran_dft
    srsran::fmt
)

# Tell the installed MEXs where to find libresource_grid.so.
set_target_properties(multiport_channel_estimator_mex
   PROPERTIES INSTALL_RPATH "${CMAKE_BINARY_DIR}/lib/support"
)

install(TARGETS multiport_channel_estimator_mex
    DESTINATION "+phy/@srsMultiPortChannelEstimator"
)
