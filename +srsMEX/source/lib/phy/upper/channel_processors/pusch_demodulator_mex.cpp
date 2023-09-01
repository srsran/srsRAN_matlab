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

#include "pusch_demodulator_mex.h"
#include "srsran_matlab/support/matlab_to_srs.h"
#include "srsran_matlab/support/to_span.h"
#include "srsran/adt/optional.h"
#include "srsran/phy/support/resource_grid_writer.h"
#include "srsran/phy/upper/channel_processors/pusch/pusch_codeword_buffer.h"
#include "srsran/phy/upper/channel_processors/pusch/pusch_demodulator_notifier.h"
#include "srsran/ran/modulation_scheme.h"

using matlab::mex::ArgumentList;
using namespace matlab::data;
using namespace srsran;
using namespace srsran_matlab;

namespace {

class pusch_codeword_buffer_spy : private pusch_codeword_buffer
{
public:
  explicit pusch_codeword_buffer_spy(span<log_likelihood_ratio> data_) : data(data_) {}

  span<const log_likelihood_ratio> get_data() const
  {
    srsran_assert(completed, "Data processing is not completed.");
    return data;
  }

  pusch_codeword_buffer& get_buffer() { return *this; }

private:
  span<log_likelihood_ratio> get_next_block_view(unsigned block_size) override
  {
    srsran_assert(!completed, "Data processing is completed.");

    block_size = std::min(block_size, static_cast<unsigned>(data.size()) - count);

    return span<log_likelihood_ratio>(data).subspan(count, block_size);
  }

  void on_new_block(span<const log_likelihood_ratio> in_block, const bit_buffer& /* scrambling_seq */) override
  {
    srsran_assert(!completed, "Data processing is completed.");
    srsran_assert(
        data.size() >= in_block.size() + count,
        "The sum of the block size (i.e., {}) and the current count (i.e., {}) exceeds the data size (i.e., {}).",
        in_block.size(),
        count,
        data.size());
    span<log_likelihood_ratio> block = get_next_block_view(in_block.size());

    if (block.data() != in_block.data()) {
      srsvec::copy(block, in_block);
    }

    count += in_block.size();
  }

  void on_end_codeword() override
  {
    srsran_assert(!completed, "Data processing is completed.");
    srsran_assert(data.size() == count, "Expected {} bits but only wrote {}.", data.size(), count);
    completed = true;
  }

  bool                       completed = false;
  span<log_likelihood_ratio> data;
  unsigned                   count = 0;
};

class pusch_demodulator_notifier_spy : private pusch_demodulator_notifier
{
public:
  pusch_demodulator_notifier& get_notifier() { return *this; }

  const demodulation_stats& get_stats() const { return stats.value(); }

private:
  void on_provisional_stats(const demodulation_stats& stats_) override { stats = stats_; }
  void on_end_stats(const demodulation_stats& stats_) override { stats = stats_; }

  srsran::optional<demodulation_stats> stats;
};

} // namespace

void MexFunction::check_step_outputs_inputs(ArgumentList& outputs, ArgumentList& inputs)
{
  if (inputs.size() != 5) {
    mex_abort("Wrong number of inputs.");
  }

  if (inputs[1].getType() != ArrayType::COMPLEX_DOUBLE) {
    mex_abort("Input 'rxSymbols' must be an array of complex double.");
  }

  if (inputs[2].getType() != ArrayType::COMPLEX_DOUBLE) {
    mex_abort("Input 'cest' must be an array of complex double.");
  }

  if ((inputs[3].getType() != ArrayType::DOUBLE) || (inputs[3].getNumberOfElements() > 1)) {
    mex_abort("Input 'noiseVar' must be a scalar double.");
  }

  if ((inputs[4].getType() != ArrayType::STRUCT) || (inputs[4].getNumberOfElements() > 1)) {
    mex_abort("Input 'PUSCHDemConfig' must be a scalar structure.");
  }

  if (outputs.size() != 1) {
    mex_abort("Wrong number of outputs.");
  }
}

static std::unique_ptr<resource_grid> create_resource_grid(unsigned nof_ports, unsigned nof_symbols, unsigned nof_subc)
{
  std::shared_ptr<channel_precoder_factory> precoding_factory = create_channel_precoder_factory("auto");
  if (!precoding_factory) {
    return nullptr;
  }
  std::shared_ptr<resource_grid_factory> rg_factory = create_resource_grid_factory(precoding_factory);
  if (!rg_factory) {
    return nullptr;
  }
  return rg_factory->create(nof_ports, nof_symbols, nof_subc);
}

void MexFunction::method_step(ArgumentList& outputs, ArgumentList& inputs)
{
  check_step_outputs_inputs(outputs, inputs);

  // Get the PUSCH demodulator configuration from MATLAB.
  StructArray in_struct_array = inputs[4];
  Struct      in_dem_cfg      = in_struct_array[0];

  // Create a PUSCH demodulator configuration object.
  pusch_demodulator::configuration demodulator_config;

  // Set the RNTI.
  demodulator_config.rnti = in_dem_cfg["RNTI"][0];

  // Build the RB allocation bitmask (contiguous PRB allocation is assumed).
  const TypedArray<bool> rb_mask_in = in_dem_cfg["RBMask"];
  demodulator_config.rb_mask        = bounded_bitset<MAX_RB>(rb_mask_in.cbegin(), rb_mask_in.cend());

  // Set the modulation scheme.
  CharArray modulation_in       = in_dem_cfg["Modulation"];
  demodulator_config.modulation = matlab_to_srs_modulation(modulation_in.toAscii());

  // PUSCH time allocation.
  demodulator_config.start_symbol_index = in_dem_cfg["StartSymbolIndex"][0];
  demodulator_config.nof_symbols        = in_dem_cfg["NumSymbols"][0];

  // Build the boolean mask of OFDM symbols carrying DM-RS.
  const TypedArray<bool> dmrs_pos_in = in_dem_cfg["DMRSSymbPos"];
  std::copy(dmrs_pos_in.cbegin(), dmrs_pos_in.cend(), demodulator_config.dmrs_symb_pos.begin());

  // DM-RS configuration type.
  demodulator_config.dmrs_config_type = matlab_to_srs_dmrs_type(in_dem_cfg["DMRSConfigType"][0]);

  // Number of CDM Groups without data.
  demodulator_config.nof_cdm_groups_without_data = in_dem_cfg["NumCDMGroupsWithoutData"][0];

  // Scrambling identifier.
  demodulator_config.n_id = in_dem_cfg["NID"][0];

  // Number of transmit layers.
  demodulator_config.nof_tx_layers = in_dem_cfg["NumLayers"][0];

  // Build the Rx port list.
  const TypedArray<double> rx_ports_in = in_dem_cfg["RxPorts"];
  for (double rxp : rx_ports_in) {
    demodulator_config.rx_ports.push_back(static_cast<uint8_t>(rxp));
  }

  // Get the PUSCH data and grid indices.
  const TypedArray<std::complex<double>> in_data_cft_array     = inputs[1];
  const TypedArray<double>               in_grid_indices_array = in_dem_cfg["PUSCHIndices"];

  // Prepare the resource grid.
  std::unique_ptr<resource_grid> grid =
      create_resource_grid(demodulator_config.rx_ports.size(),
                           demodulator_config.start_symbol_index + demodulator_config.nof_symbols,
                           demodulator_config.rb_mask.size() * NRE);
  if (!grid) {
    mex_abort("Cannot create resource grid.");
  }

  // Write zeros in grid.
  grid->set_all_zero();

  unsigned nof_rx_ports = demodulator_config.rx_ports.size();

  // Total number of received RE.
  unsigned nof_resources = in_grid_indices_array.getNumberOfElements() / 3;

  // Number of received symbols per antenna port.
  unsigned nof_rx_symbols_port = nof_resources / nof_rx_ports;

  // Put elements in the grid for the selected port.
  for (unsigned i_re = 0; i_re != nof_resources; ++i_re) {
    resource_grid_coordinate coordinate;
    coordinate.subcarrier = static_cast<uint16_t>(in_grid_indices_array[i_re][0]);
    coordinate.symbol     = static_cast<uint16_t>(in_grid_indices_array[i_re][1]);
    uint16_t i_port       = static_cast<uint16_t>(in_grid_indices_array[i_re][2]);
    cf_t     value        = static_cast<cf_t>(in_data_cft_array[coordinate.subcarrier][coordinate.symbol][i_port]);
    grid->get_writer().put(i_port, {&coordinate, 1}, {&value, 1});
  }

  // Get the channel estimates.
  const TypedArray<std::complex<double>> in_ce_cft_array = inputs[2];

  // Prepare channel estimates.
  channel_estimate::channel_estimate_dimensions ce_dims;
  ce_dims.nof_prb       = demodulator_config.rb_mask.size();
  ce_dims.nof_symbols   = MAX_NSYMB_PER_SLOT;
  ce_dims.nof_rx_ports  = nof_rx_ports;
  ce_dims.nof_tx_layers = demodulator_config.nof_tx_layers;
  channel_estimate chan_estimates(ce_dims);

  // Get the noise variance.
  float noise_var = static_cast<float>(static_cast<TypedArray<double>>(inputs[3])[0]);

  // Number of channel Resource Elements per receive port.
  unsigned nof_ch_re_port = in_ce_cft_array.getNumberOfElements() / ce_dims.nof_rx_ports;

  // Set estimated channel.
  span<const std::complex<double>> ce_port_view = to_span(in_ce_cft_array);

  for (unsigned i_rx_port = 0; i_rx_port != ce_dims.nof_rx_ports; ++i_rx_port) {
    // Copy channel estimates for a single receive port.
    srsvec::copy(chan_estimates.get_path_ch_estimate(i_rx_port, 0), ce_port_view.first(nof_ch_re_port));

    // Advance buffer.
    ce_port_view = ce_port_view.last(ce_port_view.size() - nof_ch_re_port);

    // Set noise variance.
    chan_estimates.set_noise_variance(noise_var, i_rx_port, 0);
  }

  // Compute expected soft output bit number.
  unsigned bits_per_symbol = srsran::get_bits_per_symbol(demodulator_config.modulation);

  unsigned                   nof_expected_soft_output_bits = nof_rx_symbols_port * bits_per_symbol;
  TypedArray<int8_t>         out       = factory.createArray<int8_t>({nof_expected_soft_output_bits, 1});
  span<log_likelihood_ratio> soft_bits = to_span<int8_t, log_likelihood_ratio>(out);
  pusch_codeword_buffer_spy  sch_data(soft_bits);

  // Demodulate the PUSCH transmission.
  pusch_demodulator_notifier_spy notifier;
  demodulator->demodulate(
      sch_data.get_buffer(), notifier.get_notifier(), grid->get_reader(), chan_estimates, demodulator_config);

  outputs[0] = out;
}
