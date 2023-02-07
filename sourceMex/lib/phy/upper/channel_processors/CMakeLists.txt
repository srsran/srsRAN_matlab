matlab_add_mex(
    NAME pusch_decoder_mex
    SRC pusch_decoder_mex.cpp
    R2018a
)

target_link_libraries(pusch_decoder_mex srsran::srsran_channel_processors)

set_target_properties(pusch_decoder_mex
    PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/../+srsTest/+phy/@srsPUSCHDecoder"
)

matlab_add_mex(
    NAME prach_detector_mex
    SRC prach_detector_mex.cpp
    R2018a
)

target_link_libraries(prach_detector_mex srsgnb::srsgnb_channel_processors srsgnb::srsgnb_generic_funcs)

set_target_properties(prach_detector_mex
    PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/../+srsTest/+phy/@srsPRACHDetector"
)
