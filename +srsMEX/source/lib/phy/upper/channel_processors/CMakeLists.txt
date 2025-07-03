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
    NAME prach_detector_mex
    SRC prach_detector_mex.cpp
    R2018a
)

target_link_libraries(prach_detector_mex
        srsran::srsran_channel_processors
        srsran::srsran_dft)

install(TARGETS prach_detector_mex
    DESTINATION "+phy/@srsPRACHDetector"
)

matlab_add_mex(
    NAME pusch_decoder_mex
    SRC pusch_decoder_mex.cpp
    R2018a
)

target_link_libraries(pusch_decoder_mex srsran::srsran_channel_processors)

install(TARGETS pusch_decoder_mex
    DESTINATION "+phy/@srsPUSCHDecoder"
)

matlab_add_mex(
    NAME pusch_demodulator_mex
    SRC pusch_demodulator_mex.cpp
    R2018a
)

target_link_libraries(pusch_demodulator_mex
    srsran_matlab::resource_grid
    srsran::srsran_channel_processors
    srsran::srsran_channel_equalizer
    srsran::srsran_channel_precoder
    srsran::srsran_dft
    srsran::srsran_transform_precoding
)

install(TARGETS pusch_demodulator_mex
    DESTINATION "+phy/@srsPUSCHDemodulator"
)

matlab_add_mex(
    NAME srsPUSCHCapabilitiesMEX
    SRC  pusch_processor_capabilities_mex.cpp
    R2018a
)

target_link_libraries(srsPUSCHCapabilitiesMEX
    srsran::srsran_pusch_processor
)

install(TARGETS srsPUSCHCapabilitiesMEX
    DESTINATION "+phy"
)

matlab_add_mex(
    NAME pucch_processor_mex
    SRC  pucch_processor_mex.cpp
    R2018a
)

target_link_libraries(pucch_processor_mex
    srsran_matlab::resource_grid
    srsran::srsran_channel_processors
    srsran::srsran_channel_equalizer
    srsran::srsran_phy_support
    srsran::srsran_transform_precoding
)

install(TARGETS pucch_processor_mex
    DESTINATION "+phy/@srsPUCCHProcessor"
)

# Tell the installed MEXs where to find libresource_grid.so.
set_target_properties(pucch_processor_mex pusch_demodulator_mex
   PROPERTIES INSTALL_RPATH "${CMAKE_BINARY_DIR}/lib/support"
)
