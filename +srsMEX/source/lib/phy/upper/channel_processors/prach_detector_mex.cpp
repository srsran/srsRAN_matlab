/*
 *
 * Copyright 2021-2023 Software Radio Systems Limited
 *
 * This file is part of srsRAN-matlab.
 *
 * srsRAN-matlab is free software: you can redistribute it and/or
 * modify it under the terms of the BSD 2-Clause License.
 *
 * srsRAN-matlab is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * BSD 2-Clause License for more details.
 *
 * A copy of the BSD 2-Clause License can be found in the LICENSE
 * file in the top-level directory of this distribution.
 *
 */

#include "prach_detector_mex.h"
#include "srsran_matlab/support/matlab_to_srs.h"
#include "srsran/phy/upper/channel_processors/channel_processor_formatters.h"
#include "srsran/srsvec/copy.h"

using matlab::mex::ArgumentList;
using namespace matlab::data;
using namespace srsran;
using namespace srsran_matlab;

void MexFunction::check_step_outputs_inputs(ArgumentList outputs, ArgumentList inputs)
{
  if (inputs.size() != 3) {
    mex_abort("Wrong number of inputs.");
  }

  if (inputs[1].getType() != ArrayType::COMPLEX_DOUBLE) {
    mex_abort("Input 'prach_symbols' must be an array of double.");
  }

  if ((inputs[2].getType() != ArrayType::STRUCT) || (inputs[2].getNumberOfElements() > 1)) {
    mex_abort("Input 'config' must be a scalar structure.");
  }

  if (outputs.size() != 1) {
    mex_abort("Wrong number of outputs.");
  }
}

void MexFunction::method_step(ArgumentList& outputs, ArgumentList& inputs)
{
  check_step_outputs_inputs(outputs, inputs);

  StructArray in_struct_array = inputs[2];
  Struct      in_det_cfg      = in_struct_array[0];

  CharArray restricted_set_in = in_det_cfg["restricted_set"];
  CharArray format_in         = in_det_cfg["format"];

  // Get frequency domain data.
  const TypedArray<std::complex<double>> in_cft_array = inputs[1];

  // Get dimensions.
  ArrayDimensions buffer_dimensions = inputs[1].getDimensions();
  if ((buffer_dimensions.size() != 2) && (buffer_dimensions.size() != 3)) {
    mex_abort("Invalid number of dimensions (i.e., {}).", buffer_dimensions.size());
  }
  fmt::print("-- Dimensions=[{}].\n", span<const std::size_t>(buffer_dimensions));

  // Extract dimensions.
  unsigned nof_re       = buffer_dimensions[0];
  unsigned nof_symbols  = buffer_dimensions[1];
  unsigned nof_rx_ports = 1;
  if (buffer_dimensions.size() == 3) {
    // The number of ports is one except if there is a third dimension.
    buffer_dimensions[2];
  }

  // Restricted sets are not implemented. Skip.
  prach_detector::configuration detector_config;
  detector_config.restricted_set        = matlab_to_srs_restricted_set(restricted_set_in.toAscii());
  detector_config.root_sequence_index   = in_det_cfg["root_sequence_index"][0];
  detector_config.format                = matlab_to_srs_preamble_format(format_in.toAscii());
  detector_config.zero_correlation_zone = in_det_cfg["zero_correlation_zone"][0];
  detector_config.start_preamble_index  = 0;
  detector_config.nof_preamble_indices  = 64;
  detector_config.ra_scs =
      to_ra_subcarrier_spacing(static_cast<unsigned>(1000.0 * static_cast<double>(in_det_cfg["scs"][0])));
  detector_config.nof_rx_ports = nof_rx_ports;

  // Run validator
  if (!validator->is_valid(detector_config)) {
    mex_abort("Invalid configuration:\n {:n}.", detector_config);
  }

  // Create buffer.
  std::unique_ptr<prach_buffer> buffer;
  if (nof_re == prach_constants::LONG_SEQUENCE_LENGTH) {
    buffer = create_prach_buffer_long(nof_rx_ports, 1);
  } else if (nof_re == prach_constants::SHORT_SEQUENCE_LENGTH) {
    buffer = create_prach_buffer_short(nof_rx_ports, 1, 1);
  } else {
    mex_abort("Invalid number of samples. Dimensions=[{}].", span<const std::size_t>(buffer_dimensions));
  }

  if (!buffer) {
    mex_abort("Cannot create srsran PRACH buffer long.");
  }

  // Fill buffer with time frequency-domain data.
  for (unsigned i_rx_port = 0; i_rx_port != nof_rx_ports; ++i_rx_port) {
    for (unsigned i_symbol = 0; i_symbol != nof_symbols; ++i_symbol) {
      span<cf_t> symbol_view = buffer->get_symbol(i_rx_port, 0, 0, i_symbol);
      for (unsigned i_sample = 0; i_sample != nof_re; ++i_sample) {
        symbol_view[i_sample] = cf_t(in_cft_array[i_sample][i_symbol][i_rx_port]);
      }
    }
  }

  // Run detector.
  prach_detection_result result = detector->detect(*buffer, detector_config);

  // Detected PRACH preamble parameters.
  StructArray detected_preamble_indication = factory.createStructArray({result.preambles.size(), 1},
                                                                       {"nof_detected_preambles",
                                                                        "preamble_index",
                                                                        "time_advance",
                                                                        "power_dB",
                                                                        "snr_dB",
                                                                        "rssi_dB",
                                                                        "time_resolution",
                                                                        "time_advance_max"});
  for (unsigned i_preamble = 0, i_preamble_end = result.preambles.size(); i_preamble != i_preamble_end; ++i_preamble) {
    const prach_detection_result::preamble_indication& preamble = result.preambles[i_preamble];

    detected_preamble_indication[i_preamble]["nof_detected_preambles"] = factory.createScalar(result.preambles.size());
    detected_preamble_indication[i_preamble]["preamble_index"]         = factory.createScalar(preamble.preamble_index);
    detected_preamble_indication[i_preamble]["time_advance"] = factory.createScalar(preamble.time_advance.to_seconds());
    detected_preamble_indication[i_preamble]["power_dB"]     = factory.createScalar(preamble.power_dB);
    detected_preamble_indication[i_preamble]["snr_dB"]       = factory.createScalar(preamble.snr_dB);
    detected_preamble_indication[i_preamble]["rssi_dB"]      = factory.createScalar(result.rssi_dB);
    detected_preamble_indication[i_preamble]["time_resolution"] =
        factory.createScalar(result.time_resolution.to_seconds());
    detected_preamble_indication[i_preamble]["time_advance_max"] =
        factory.createScalar(result.time_advance_max.to_seconds());
  }
  outputs[0] = detected_preamble_indication;
}
