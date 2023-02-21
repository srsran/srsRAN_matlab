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
