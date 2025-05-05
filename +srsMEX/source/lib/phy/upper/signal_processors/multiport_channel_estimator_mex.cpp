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
/// \brief Multiport channel estimator MEX definition.

#include "multiport_channel_estimator_mex.h"
#include "srsran_matlab/support/matlab_to_srs.h"
#include "srsran_matlab/support/resource_grid.h"
#include "srsran_matlab/support/to_span.h"
#include "srsran/phy/support/resource_grid_writer.h"
#include "srsran/srsvec/conversion.h"
#include <MatlabDataArray/ArrayDimensions.hpp>

using namespace matlab::data;
using namespace srsran;
using namespace srsran_matlab;

void MexFunction::method_new(ArgumentList outputs, ArgumentList inputs)
{
  constexpr unsigned NOF_INPUTS = 4;
  if (inputs.size() != NOF_INPUTS) {
    mex_abort("Wrong number of inputs: expected {}, provided {}.", NOF_INPUTS, inputs.size());
  }

  if (inputs[1].getType() != ArrayType::CHAR) {
    mex_abort("Input 'smoothing' must be a string.");
  }
  std::string                                  fd_smoothing_string = static_cast<CharArray>(inputs[1]).toAscii();
  port_channel_estimator_fd_smoothing_strategy fd_smoothing        = port_channel_estimator_fd_smoothing_strategy::none;
  if (fd_smoothing_string == "filter") {
    fd_smoothing = port_channel_estimator_fd_smoothing_strategy::filter;
  } else if (fd_smoothing_string == "mean") {
    fd_smoothing = port_channel_estimator_fd_smoothing_strategy::mean;
  } else if (fd_smoothing_string != "none") {
    mex_abort("Unknown FD smoothing strategy {}.", fd_smoothing_string);
  }

  if (inputs[2].getType() != ArrayType::CHAR) {
    mex_abort("Input 'interpolation' must be a string.");
  }
  std::string td_interpolation_string = static_cast<CharArray>(inputs[2]).toAscii();
  port_channel_estimator_td_interpolation_strategy td_interpolation =
      port_channel_estimator_td_interpolation_strategy::average;
  if (td_interpolation_string == "interpolate") {
    td_interpolation = port_channel_estimator_td_interpolation_strategy::interpolate;
  } else if (td_interpolation_string != "average") {
    mex_abort("Unknown TD interpolation strategy {}.", td_interpolation_string);
  }

  if ((inputs[3].getType() != ArrayType::LOGICAL) && (inputs[3].getNumberOfElements() > 1)) {
    mex_abort("Input 'compensateCFO' should be a scalar logical.");
  }
  bool compensate_cfo = static_cast<TypedArray<bool>>(inputs[3])[0];

  if (!outputs.empty()) {
    mex_abort("Wrong number of outputs: expected 0, provided {}.", outputs.size());
  }

  estimator = create_port_channel_estimator(fd_smoothing, td_interpolation, compensate_cfo);

  // Ensure the estimator was created properly.
  if (!estimator) {
    mex_abort("Cannot create srsRAN port channel estimator.");
  }
}

void MexFunction::check_step_outputs_inputs(ArgumentList outputs, ArgumentList inputs)
{
  constexpr unsigned NOF_INPUTS = 5;
  if (inputs.size() != NOF_INPUTS) {
    mex_abort("Wrong number of inputs: expected {}, provided {}.", NOF_INPUTS, inputs.size());
  }

  ArrayDimensions in1_dims = inputs[1].getDimensions();
  if ((inputs[1].getType() != ArrayType::COMPLEX_SINGLE) || (in1_dims.size() < 2) || (in1_dims.size() > 3)) {
    mex_abort("Input 'rxGrid' should be a 2- or 3-dimensional array of complex floats, provided [{}].", in1_dims);
  }

  if ((inputs[2].getType() != ArrayType::DOUBLE) || (inputs[2].getNumberOfElements() != 2)) {
    mex_abort("Input 'symbolAllocation' should contain two elements only.");
  }

  if (inputs[3].getType() != ArrayType::COMPLEX_SINGLE) {
    mex_abort("Input 'refSym' should contain complex float symbols.");
  }

  ArrayDimensions in3dims = inputs[3].getDimensions();
  if (in3dims.size() > 2) {
    mex_abort("Input 'refSym' can have at most 2 dimensions provided size {}.", in3dims.size());
  }
  if ((in3dims.size() != 1) && (in3dims[1] > 4)) {
    mex_abort("Input 'refSym' can have at most 4 columns (i.e., 4 Tx layers) - provided size {}.", in3dims[1]);
  }

  if ((inputs[4].getType() != ArrayType::STRUCT) || (inputs[4].getNumberOfElements() > 1)) {
    mex_abort("Input 'config' should be a scalar structure.");
  }

  constexpr unsigned NOF_OUTPUTS = 2;
  if (outputs.size() != NOF_OUTPUTS) {
    mex_abort("Wrong number of outputs: expected {}, provided {}.", NOF_OUTPUTS, outputs.size());
  }
}

void MexFunction::method_step(ArgumentList outputs, ArgumentList inputs)
{
  // Ensure the estimator is initialized.
  if (!estimator) {
    mex_abort("The srsRAN channel estimator was not initialized properly.");
  }

  check_step_outputs_inputs(outputs, inputs);

  StructArray  in_cfg_array = inputs[4];
  const Struct in_cfg       = in_cfg_array[0];

  port_channel_estimator::configuration cfg   = {};
  const CharArray                       in_cp = in_cfg["CyclicPrefix"];
  cfg.cp                                      = matlab_to_srs_cyclic_prefix(in_cp.toAscii());

  cfg.scs = matlab_to_srs_subcarrier_spacing(static_cast<unsigned>(in_cfg["SubcarrierSpacing"][0]));

  const TypedArray<double> in_allocation = inputs[2];
  cfg.first_symbol                       = static_cast<unsigned>(in_allocation[0]);
  cfg.nof_symbols                        = static_cast<unsigned>(in_allocation[1]);

  ArrayDimensions pilots_dimensions = inputs[3].getDimensions();
  unsigned        nof_layers        = pilots_dimensions[1];

  cfg.dmrs_pattern.resize(nof_layers);

  const TypedArray<bool>   in_symbols         = in_cfg["Symbols"];
  const TypedArray<bool>   in_rb_mask         = in_cfg["RBMask"];
  const TypedArray<bool>   in_rb_mask2        = in_cfg["RBMask2"];
  const TypedArray<double> in_hop             = in_cfg["HoppingIndex"];
  const TypedArray<bool>   in_re_pattern_cdm0 = in_cfg["REPatternCDM0"];
  const TypedArray<bool>   in_re_pattern_cdm1 = in_cfg["REPatternCDM1"];

  if ((nof_layers > 2) && in_re_pattern_cdm1.isEmpty()) {
    mex_abort("Configuration with {} layers but only one RE pattern.", nof_layers);
  }

  for (unsigned i_layer = 0; i_layer != nof_layers; ++i_layer) {
    // Since we consider at most the first two layers (0 and 1), the corresponding DM-RS occupy the same resources.
    port_channel_estimator::layer_dmrs_pattern& dmrs_pattern = cfg.dmrs_pattern[i_layer];

    dmrs_pattern.symbols = bounded_bitset<MAX_NSYMB_PER_SLOT>(in_symbols.cbegin(), in_symbols.cend());
    dmrs_pattern.rb_mask = prb_bitmap(in_rb_mask.cbegin(), in_rb_mask.cend());

    if (!in_hop.isEmpty()) {
      dmrs_pattern.hopping_symbol_index = static_cast<unsigned>(in_hop[0]);
      dmrs_pattern.rb_mask2             = prb_bitmap(in_rb_mask2.cbegin(), in_rb_mask2.cend());
    }

    if (i_layer < 2) {
      dmrs_pattern.re_pattern = bounded_bitset<NRE>(in_re_pattern_cdm0.cbegin(), in_re_pattern_cdm0.cend());
    } else {
      dmrs_pattern.re_pattern = bounded_bitset<NRE>(in_re_pattern_cdm1.cbegin(), in_re_pattern_cdm1.cend());
    }
  }

  cfg.scaling = static_cast<float>(in_cfg["BetaScaling"][0]);

  // Read the resource grid from inputs[1].
  std::unique_ptr<resource_grid> grid = read_resource_grid(inputs[1]);
  if (!grid) {
    mex_abort("Cannot create resource grid.");
  }

  unsigned                 nof_rx_ports     = grid->get_writer().get_nof_ports();
  const TypedArray<double> in_port_indices  = in_cfg["PortIndices"];
  unsigned                 nof_port_indices = in_port_indices.getNumberOfElements();
  if (nof_port_indices != nof_rx_ports) {
    mex_abort("PortIndices and number of resource grid ports do not match: {} vs. {}.", nof_port_indices, nof_rx_ports);
  }
  cfg.rx_ports.resize(nof_rx_ports);
  for (unsigned i_port = 0; i_port != nof_rx_ports; ++i_port) {
    cfg.rx_ports[i_port] = static_cast<unsigned>(in_port_indices[i_port]);
  }

  // Read the DM-RS.
  const TypedArray<cf_t> in_pilots = inputs[3];

  port_channel_estimator::layer_dmrs_pattern& dmrs_pattern = cfg.dmrs_pattern[0];
  unsigned nof_pilot_res     = dmrs_pattern.rb_mask.count() * dmrs_pattern.re_pattern.count();
  unsigned nof_pilot_symbols = dmrs_pattern.symbols.count();
  if (in_pilots.getNumberOfElements() != nof_pilot_res * nof_pilot_symbols * nof_layers) {
    mex_abort("Expected {} DM-RS symbols over {} layers, received {}.",
              nof_pilot_res * nof_pilot_symbols * nof_layers,
              nof_layers,
              in_pilots.getNumberOfElements());
  }
  span<const cf_t> pilot_view = to_span(in_pilots);

  re_measurement_dimensions pilot_dims;
  pilot_dims.nof_subc    = nof_pilot_res;
  pilot_dims.nof_symbols = nof_pilot_symbols;
  pilot_dims.nof_slices  = nof_layers;

  unsigned         nof_pilot_layer = nof_pilot_res * nof_pilot_symbols;
  dmrs_symbol_list pilots(pilot_dims);
  for (unsigned i_layer = 0; i_layer != nof_layers; ++i_layer) {
    pilots.set_slice(pilot_view.first(nof_pilot_layer), i_layer);
    pilot_view = pilot_view.last(pilot_view.size() - nof_pilot_layer);
  }

  channel_estimate::channel_estimate_dimensions ch_est_dims;
  ch_est_dims.nof_prb       = dmrs_pattern.rb_mask.size();
  ch_est_dims.nof_symbols   = dmrs_pattern.symbols.size();
  ch_est_dims.nof_rx_ports  = nof_rx_ports;
  ch_est_dims.nof_tx_layers = nof_layers;
  channel_estimate ch_estimate(ch_est_dims);

  for (unsigned i_port = 0; i_port != nof_rx_ports; ++i_port) {
    estimator->compute(ch_estimate, grid->get_reader(), i_port, pilots, cfg);
  }

  TypedArray<cf_t> ch_est_out = factory.createArray<cf_t>(
      {static_cast<size_t>(ch_est_dims.nof_prb * NRE), ch_est_dims.nof_symbols, nof_rx_ports, nof_layers});
  span<cf_t> ch_est_out_view = to_span(ch_est_out);
  for (unsigned i_layer = 0; i_layer != nof_layers; ++i_layer) {
    for (unsigned i_port = 0; i_port != nof_rx_ports; ++i_port) {
      span<const cbf16_t> ch_estimate_view = ch_estimate.get_path_ch_estimate(i_port, i_layer);

      srsvec::convert(ch_est_out_view.first(ch_estimate_view.size()), ch_estimate_view);

      ch_est_out_view = ch_est_out_view.last(ch_est_out_view.size() - ch_estimate_view.size());
    }
  }

  StructArray info_out =
      factory.createStructArray({nof_rx_ports + 1, 1}, {"NoiseVar", "RSRP", "EPRE", "SINR", "TimeAlignment", "CFO"});
  float  total_noise_var      = 0;
  float  total_rsrp           = 0;
  float  total_epre           = 0;
  double total_time_alignment = 0;
  double total_cfo            = 0;
  for (unsigned i_port = 0; i_port != nof_rx_ports; ++i_port) {
    info_out[i_port]["NoiseVar"] = factory.createScalar(static_cast<double>(ch_estimate.get_noise_variance(i_port)));
    total_noise_var += ch_estimate.get_noise_variance(i_port);
    info_out[i_port]["RSRP"] = factory.createScalar(static_cast<double>(ch_estimate.get_rsrp(i_port)));
    total_rsrp += ch_estimate.get_rsrp(i_port);
    info_out[i_port]["EPRE"] = factory.createScalar(static_cast<double>(ch_estimate.get_epre(i_port)));
    total_epre += ch_estimate.get_epre(i_port);
    info_out[i_port]["SINR"] = factory.createScalar(static_cast<double>(ch_estimate.get_snr(i_port)));
    info_out[i_port]["TimeAlignment"] =
        factory.createScalar(static_cast<double>(ch_estimate.get_time_alignment(i_port).to_seconds()));
    total_time_alignment += ch_estimate.get_time_alignment(i_port).to_seconds();
    if (ch_estimate.get_cfo_Hz(i_port).has_value()) {
      info_out[i_port]["CFO"] = factory.createScalar(static_cast<double>(ch_estimate.get_cfo_Hz(i_port).value()));
      total_cfo += static_cast<double>(ch_estimate.get_cfo_Hz(i_port).value());
    } else {
      info_out[i_port]["CFO"] = factory.createEmptyArray();
      total_cfo               = std::numeric_limits<float>::quiet_NaN();
    }
  }

  // In the last "info_out" we store the global metrics.
  total_noise_var /= static_cast<float>(nof_rx_ports);
  info_out[nof_rx_ports]["NoiseVar"] = factory.createScalar(static_cast<double>(total_noise_var));
  info_out[nof_rx_ports]["RSRP"]     = factory.createScalar(static_cast<double>(total_rsrp / nof_rx_ports));
  info_out[nof_rx_ports]["EPRE"]     = factory.createScalar(static_cast<double>(total_epre / nof_rx_ports));
  // A global SINR doesn't make much sense, we need to know how the ports are combined.
  info_out[nof_rx_ports]["SINR"]          = factory.createScalar(std::numeric_limits<double>::quiet_NaN());
  info_out[nof_rx_ports]["TimeAlignment"] = factory.createScalar(total_time_alignment / nof_rx_ports);
  if (!std::isnan(total_cfo)) {
    info_out[nof_rx_ports]["CFO"] = factory.createScalar(total_cfo / nof_rx_ports);
  } else {
    info_out[nof_rx_ports]["CFO"] = factory.createEmptyArray();
  }

  outputs[0] = ch_est_out;
  outputs[1] = info_out;
}
