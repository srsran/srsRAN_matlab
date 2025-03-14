/*
 *
 * Copyright 2021-2025 Software Radio Systems Limited
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

/// \file
/// \brief PUCCH detector MEX definition.

#include "pucch_detector_mex.h"
#include "srsran_matlab/support/matlab_to_srs.h"
#include "srsran_matlab/support/resource_grid.h"
#include "srsran_matlab/support/to_span.h"
#include "srsran/phy/constants.h"
#include "srsran/srsvec/conversion.h"
#include <memory>

using namespace matlab::data;
using namespace srsran;
using namespace srsran_matlab;

void MexFunction::check_step_outputs_inputs(ArgumentList outputs, ArgumentList inputs)
{
  constexpr unsigned NOF_INPUTS = 5;
  if (inputs.size() != NOF_INPUTS) {
    mex_abort("Wrong number of inputs: expected {}, provided {}.", NOF_INPUTS, inputs.size());
  }

  ArrayDimensions in1_dims = inputs[1].getDimensions();
  if ((inputs[1].getType() != ArrayType::COMPLEX_SINGLE) || (in1_dims.size() < 2) || (in1_dims.size() > 3)) {
    mex_abort("Input 'rxGrid' should be a 2- or 3-dimensional array of complex floats, provided {} dimensions.",
              in1_dims.size());
  }

  ArrayDimensions in2_dims = inputs[2].getDimensions();
  if ((inputs[2].getType() != ArrayType::COMPLEX_SINGLE) || (in2_dims.size() < 2) || (in2_dims.size() > 3)) {
    mex_abort("Input 'chEstimates' should be a 2- or 3-dimensional array of complex floats, provided {} dimensions.",
              in2_dims.size());
  }

  if (!std::equal(in1_dims.cbegin(), in1_dims.cend(), in2_dims.cbegin(), in2_dims.cend())) {
    mex_abort(
        "Inputs 'rxGrid' and 'chEstimates' should have the same size, provided [{}] and [{}].", in1_dims, in2_dims);
  }

  ArrayDimensions in3_dims     = inputs[3].getDimensions();
  bool            is_in3_array = (in3_dims.size() == 2);
  is_in3_array                 = is_in3_array && ((in3_dims[0] == 1) || (in3_dims[1] == 1));
  if ((inputs[3].getType() != ArrayType::SINGLE) || !is_in3_array) {
    mex_abort("Input 'noiseVars' should be a single-dimension array of floats.");
  }

  if ((inputs[4].getType() != ArrayType::STRUCT) || (inputs[4].getNumberOfElements() > 1)) {
    mex_abort("Input 'config' should be a scala structure.");
  }

  constexpr unsigned NOF_OUTPUTS = 3;
  if (outputs.size() != NOF_OUTPUTS) {
    mex_abort("Wrong number of outputs: expected {}, provided {}.", NOF_OUTPUTS, outputs.size());
  }
}

/// \brief Creates a channel estimate from a MATLAB multidimensional array.
///
/// \param[out] ch_est     The channel estimate as an object from the srsRAN data API.
/// \param[in]  in_ch_est  The channel estimates as a multidimensional (2D or 3D) array of complex floats, as passed by
///                        MATLAB to the MEX.
static void read_channel_estimate(channel_estimate& ch_est, const TypedArray<cf_t>& in_ch_est)
{
  ArrayDimensions in_dims = in_ch_est.getDimensions();

  channel_estimate::channel_estimate_dimensions ch_dims;
  ch_dims.nof_prb      = in_dims[0] / NRE;
  ch_dims.nof_symbols  = in_dims[1];
  ch_dims.nof_rx_ports = 1;
  // A third dimension means multiple Rx ports.
  if (in_dims.size() > 2) {
    ch_dims.nof_rx_ports = in_dims[2];
  }
  // PUCCH transmissions are single layer.
  ch_dims.nof_tx_layers = 1;

  srsran_assert(ch_dims.nof_prb <= MAX_RB,
                "The number of PRBs in the channel estimate should not exceed {}, given {}.",
                MAX_RB,
                ch_dims.nof_prb);

  srsran_assert(in_dims[0] % NRE == 0, "The number of REs should be a multiple of {}, given {}.", NRE, in_dims[0]);

  srsran_assert(ch_dims.nof_symbols <= MAX_NSYMB_PER_SLOT,
                "The number of OFDM symbols should not exceed {}, given {}.",
                MAX_NSYMB_PER_SLOT,
                ch_dims.nof_symbols);

  srsran_assert(
      ch_dims.nof_rx_ports <= 4, "The number of Rx ports should not exceed 4, given {}.", ch_dims.nof_rx_ports);

  // Resize the output channel estimate object according to the input dimensions.
  ch_est.resize(ch_dims);

  // Fill the output estimate with the values in the input one.
  // Create a view spanning the entire channel estimate (subcarriers, symbols, ports).
  span<const cf_t> in_view = to_span(in_ch_est);

  // Number of REs for port (i.e., number of subcarriers times number of symbols).
  unsigned port_res      = in_dims[0] * ch_dims.nof_symbols;
  unsigned remaining_res = port_res * ch_dims.nof_rx_ports;

  for (unsigned i_port = 0; i_port != ch_dims.nof_rx_ports; ++i_port) {
    span<cbf16_t>    path    = ch_est.get_path_ch_estimate(i_port, 0);
    span<const cf_t> in_path = in_view.first(port_res);
    remaining_res -= port_res;
    in_view = in_view.last(remaining_res);

    srsvec::convert(path, in_path);
  }
}

static pucch_detector::format1_configuration populate_f1_configuration(const Struct& in_cfg)
{
  // Create a PUCCH F1 configuration object.
  pucch_detector::format1_configuration cfg = {};

  // Set the slot point.
  unsigned scs_kHz    = static_cast<unsigned>(in_cfg["SubcarrierSpacing"][0]);
  unsigned slot_count = static_cast<unsigned>(in_cfg["NSlot"][0]);
  cfg.slot            = {matlab_to_srs_subcarrier_spacing(scs_kHz), slot_count};

  // Set the cyclic prefix.
  const CharArray in_cp = in_cfg["CP"];
  cfg.cp                = matlab_to_srs_cyclic_prefix(in_cp.toAscii());

  unsigned nof_ports = static_cast<unsigned>(in_cfg["NRxPorts"][0]);
  cfg.ports.clear();
  for (unsigned i_port = 0; i_port != nof_ports; ++i_port) {
    cfg.ports.push_back(i_port);
  }

  // Set the frequency allocation.
  cfg.starting_prb   = static_cast<unsigned>(in_cfg["StartPRB"][0]);
  cfg.second_hop_prb = std::nullopt;
  if (!in_cfg["SecondHopStartPRB"].isEmpty()) {
    cfg.second_hop_prb = static_cast<unsigned>(in_cfg["SecondHopStartPRB"][0]);
  }

  // Group hopping is not supported at the moment.
  cfg.group_hopping = pucch_group_hopping::NEITHER;

  // Set the time allocation.
  cfg.start_symbol_index = static_cast<unsigned>(in_cfg["StartSymbolIndex"][0]);
  cfg.nof_symbols        = static_cast<unsigned>(in_cfg["NumOFDMSymbols"][0]);

  // Set the scrambling identifier.
  cfg.n_id = static_cast<unsigned>(in_cfg["NID"][0]);

  // Set the lengths of UCI fields.
  cfg.nof_harq_ack = static_cast<unsigned>(in_cfg["NumHARQAck"][0]);

  // Set the initial cyclic shift.
  cfg.initial_cyclic_shift = static_cast<unsigned>(in_cfg["InitialCyclicShift"][0]);

  // Set the time domain orthogonal cyclic code.
  cfg.time_domain_occ = static_cast<unsigned>(in_cfg["OCCI"][0]);

  // Set the DM-RS amplitude scaling factor.
  cfg.beta_pucch = static_cast<float>(in_cfg["Beta"][0]);

  return cfg;
}

void MexFunction::method_step(ArgumentList outputs, ArgumentList inputs)
{
  check_step_outputs_inputs(outputs, inputs);

  // Read the resource grid from inputs[1].
  // TODO(david): this is not good for memory allocation.
  std::unique_ptr<resource_grid> grid = read_resource_grid(inputs[1]);
  if (!grid) {
    mex_abort("Cannot create resource grid.");
  }

  read_channel_estimate(ch_est, inputs[2]);

  // Get the noise variances and load them into the CSI.
  TypedArray<float> noise_vars = inputs[3];

  for (unsigned i_port = 0, nof_ports = noise_vars.getNumberOfElements(); i_port != nof_ports; ++i_port) {
    ch_est.set_noise_variance(noise_vars[i_port], i_port);
  }

  // Read the configuration structure.
  StructArray                                 in_cfg_array = inputs[4];
  const Struct                                in_cfg       = in_cfg_array[0];
  const pucch_detector::format1_configuration cfg          = populate_f1_configuration(in_cfg);

  pucch_detector::pucch_detection_result result = detector->detect(grid->get_reader(), ch_est, cfg);

  CharArray           status        = factory.createCharArray(srsran::to_string(result.uci_message.get_status()));
  TypedArray<uint8_t> harq_ack_bits = fill_message_fields(result.uci_message.get_harq_ack_bits());
  TypedArray<uint8_t> sr_bits       = fill_message_fields(result.uci_message.get_sr_bits());

  outputs[0] = status;
  outputs[1] = harq_ack_bits;
  outputs[2] = sr_bits;
}

TypedArray<uint8_t> MexFunction::fill_message_fields(span<const uint8_t> field)
{
  if (field.empty()) {
    // The MEX API seems to have some issue when returning an empty array. Since this is a binary array, we use 9 as a
    // tag.
    return factory.createArray<uint8_t>({1, 1}, {9});
  }

  unsigned nof_bits = field.size();
  return factory.createArray({nof_bits, 1}, field.begin(), field.end());
}
