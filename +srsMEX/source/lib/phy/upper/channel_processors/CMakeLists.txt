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

matlab_add_mex(
    NAME prach_detector_mex
    SRC prach_detector_mex.cpp
    R2018a
)

target_link_libraries(prach_detector_mex srsran::srsran_channel_processors srsran::srsran_generic_funcs)

set_target_properties(prach_detector_mex
    PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/../../+srsMEX/+phy/@srsPRACHDetector"
)

matlab_add_mex(
    NAME pusch_decoder_mex
    SRC pusch_decoder_mex.cpp
    R2018a
)

target_link_libraries(pusch_decoder_mex srsran::srsran_channel_processors)

set_target_properties(pusch_decoder_mex
    PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/../../+srsMEX/+phy/@srsPUSCHDecoder"
)

matlab_add_mex(
    NAME pusch_demodulator_mex
    SRC pusch_demodulator_mex.cpp
    R2018a
)

target_link_libraries(pusch_demodulator_mex srsran::srsran_channel_processors srsran::srsran_channel_equalizer srsran::srsran_channel_precoder)

set_target_properties(pusch_demodulator_mex
    PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/../../+srsMEX/+phy/@srsPUSCHDemodulator"
)
