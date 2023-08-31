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
#include "srsran/adt/optional.h"
#include "srsran/phy/support/resource_grid_writer.h"
#include "srsran/phy/upper/channel_processors/pusch/pusch_codeword_buffer.h"
#include "srsran/phy/upper/channel_processors/pusch/pusch_demodulator_notifier.h"

using matlab::mex::ArgumentList;
using namespace matlab::data;
using namespace srsran;
using namespace srsran_matlab;

namespace {

class pusch_codeword_buffer_spy : private pusch_codeword_buffer
{
public:
  pusch_codeword_buffer_spy(unsigned size) : data(size) {}

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
    srsran_assert(
        data.size() >= block_size + count,
        "The sum of the block size (i.e., {}) and the current count (i.e., {}) exceeds the data size (i.e., {}).",
        block_size,
        count,
        data.size());
    return span<log_likelihood_ratio>(data).subspan(count, block_size);
  }

  void on_new_block(span<const log_likelihood_ratio> demodulated, span<const log_likelihood_ratio> descrambled) override
  {
    srsran_assert(!completed, "Data processing is completed.");
    span<log_likelihood_ratio> block = get_next_block_view(demodulated.size());

    if (block.data() != demodulated.data()) {
      srsvec::copy(block, demodulated);
    }

    count += demodulated.size();
  }

  void on_end_codeword() override
  {
    srsran_assert(!completed, "Data processing is completed.");
    srsran_assert(data.size() == count, "Expected {} bits but only wrote {}.", data.size(), count);
    completed = true;
  }

  bool                              completed = false;
  std::vector<log_likelihood_ratio> data;
  unsigned                          count = 0;
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

void MexFunction::check_step_outputs_inputs(ArgumentList outputs, ArgumentList inputs)
{
  if (inputs.size() != 6) {
    mex_abort("Wrong number of inputs.");
  }

  if (inputs[1].getType() != ArrayType::COMPLEX_DOUBLE) {
    mex_abort("Input 'rxSymbols' must be an array of complex double.");
  }

  if (inputs[2].getType() != ArrayType::DOUBLE) {
    mex_abort("Input 'puschIndices' must be an array of double.");
  }

  if (inputs[3].getType() != ArrayType::COMPLEX_DOUBLE) {
    mex_abort("Input 'ce' must be an array of complex double.");
  }

  if ((inputs[4].getType() != ArrayType::STRUCT) || (inputs[4].getNumberOfElements() > 1)) {
    mex_abort("Input 'PUSCHDemConfig' must be a scalar structure.");
  }

  if ((inputs[5].getType() != ArrayType::DOUBLE) || (inputs[5].getNumberOfElements() > 1)) {
    mex_abort("Input 'noiseVar' must be a scalar double.");
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
  StructArray                      in_struct_array = inputs[4];
  Struct                           in_dem_cfg      = in_struct_array[0];
  pusch_demodulator::configuration demodulator_config;

  // Build the RB allocation bitmask (contiguous PRB allocation is assumed).
  const TypedArray<double> rb_mask_in          = in_dem_cfg["rbMask"];
  unsigned                 num_of_rb           = rb_mask_in.getNumberOfElements();
  unsigned                 start_prb_index     = 0;
  unsigned                 end_prb_index       = 0;
  bool                     start_prb_index_set = false;
  for (unsigned rb_index = 0; rb_index != num_of_rb; ++rb_index) {
    if (rb_mask_in[rb_index] == 1) {
      if (!start_prb_index_set) {
        start_prb_index     = rb_index;
        start_prb_index_set = true;
      } else {
        end_prb_index = rb_index;
      }
    }
  }
  bounded_bitset<MAX_RB> prb_mask;
  prb_mask.resize(num_of_rb);
  prb_mask.fill(start_prb_index, end_prb_index + 1);

  // Build the DM-RS symbol position bitmask.
  const TypedArray<double>             dmrs_pos_in   = in_dem_cfg["dmrsSymbPos"];
  std::array<bool, MAX_NSYMB_PER_SLOT> dmrs_symb_pos = {};
  for (unsigned symb_index = 0; symb_index != MAX_NSYMB_PER_SLOT; ++symb_index) {
    dmrs_symb_pos[symb_index] = (dmrs_pos_in[symb_index] == 1);
  }

  // Build the rx port list.
  const TypedArray<double>          rx_ports_in     = in_dem_cfg["rxPorts"];
  unsigned                          num_of_rx_ports = rx_ports_in.getNumberOfElements();
  static_vector<uint8_t, MAX_PORTS> rx_ports;
  for (unsigned rx_port = 0; rx_port != num_of_rx_ports; ++rx_port) {
    rx_ports.push_back(static_cast<uint8_t>(rx_ports_in[rx_port]));
  }

  // Set the PUSCH demodulator configuration.
  demodulator_config.rnti                        = in_dem_cfg["rnti"][0];
  demodulator_config.rb_mask                     = prb_mask;
  CharArray modulation_in                        = in_dem_cfg["modulation"];
  demodulator_config.modulation                  = matlab_to_srs_modulation(modulation_in.toAscii());
  demodulator_config.start_symbol_index          = in_dem_cfg["startSymbolIndex"][0];
  demodulator_config.nof_symbols                 = in_dem_cfg["nofSymbols"][0];
  demodulator_config.dmrs_symb_pos               = dmrs_symb_pos;
  demodulator_config.dmrs_config_type            = matlab_to_srs_dmrs_type(in_dem_cfg["dmrsConfigType"][0]);
  demodulator_config.nof_cdm_groups_without_data = in_dem_cfg["nofCdmGroupsWithoutData"][0];
  demodulator_config.n_id                        = in_dem_cfg["nId"][0];
  demodulator_config.nof_tx_layers               = in_dem_cfg["nofTxLayers"][0];
  demodulator_config.rx_ports                    = rx_ports;

  // Get the PUSCH data and grid indices.
  const TypedArray<std::complex<double>> in_data_cft_array = inputs[1];
  std::vector<cf_t>                      rx_symbols(in_data_cft_array.cbegin(), in_data_cft_array.cend());
  const TypedArray<double>               in_grid_indices_array = inputs[2];

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
  unsigned nof_resources = rx_symbols.size();

  // Number of received symbols per antenna port.
  unsigned nof_rx_symbols_port = nof_resources / nof_rx_ports;

  // Setup resource grid symbols.
  for (unsigned i_port = 0, i_port_end = demodulator_config.rx_ports.size(); i_port != i_port_end; ++i_port) {
    // Create vector of coordinates and values for the port.
    std::vector<resource_grid_coordinate> coordinates(0);
    std::vector<cf_t>                     values(0);

    // Reserve to avoid continuous memory allocation.
    coordinates.reserve(nof_resources);
    values.reserve(nof_resources);

    // Select the grid entries that match the port.
    for (unsigned i_re = 0; i_re < nof_resources; ++i_re) {
      if (in_grid_indices_array[i_re][2] == i_port) {
        resource_grid_coordinate coordinate;
        coordinate.subcarrier = static_cast<uint16_t>(in_grid_indices_array[i_re][0]);
        coordinate.symbol     = static_cast<uint16_t>(in_grid_indices_array[i_re][1]);
        coordinates.emplace_back(coordinate);
        values.emplace_back(rx_symbols[i_re]);
      }
    }

    // Put elements in the grid for the selected port.
    grid->get_writer().put(i_port, coordinates, values);
  }

  // Get the channel estimates.
  const TypedArray<std::complex<double>> in_ce_cft_array = inputs[3];
  std::vector<cf_t>                      ce(in_ce_cft_array.cbegin(), in_ce_cft_array.cend());

  // Prepare channel estimates.
  channel_estimate::channel_estimate_dimensions ce_dims;
  ce_dims.nof_prb       = demodulator_config.rb_mask.size();
  ce_dims.nof_symbols   = MAX_NSYMB_PER_SLOT;
  ce_dims.nof_rx_ports  = nof_rx_ports;
  ce_dims.nof_tx_layers = demodulator_config.nof_tx_layers;
  channel_estimate chan_estimates(ce_dims);

  // Get the noise variance.
  float noise_var = (float)inputs[5][0];

  // Number of channel Resource Elements per receive port.
  unsigned nof_ch_re_port = ce.size() / ce_dims.nof_rx_ports;

  // Set estimated channel.
  span<const cf_t> ce_port_view(ce);
  for (unsigned i_rx_port = 0; i_rx_port != ce_dims.nof_rx_ports; ++i_rx_port) {
    // Copy channel estimates for a single receive port.
    srsvec::copy(chan_estimates.get_path_ch_estimate(i_rx_port, 0), ce_port_view.first(nof_ch_re_port));

    // Advance buffer.
    ce_port_view = ce_port_view.last(ce_port_view.size() - nof_ch_re_port);

    // Set noise variance.
    chan_estimates.set_noise_variance(noise_var, i_rx_port, 0);
  }

  // Compute expected soft output bit number.
  unsigned bits_per_symbol = 0;
  switch (demodulator_config.modulation) {
    case srsran::modulation_scheme::PI_2_BPSK:
      bits_per_symbol = 1;
      break;
    case srsran::modulation_scheme::QPSK:
      bits_per_symbol = 2;
      break;
    case srsran::modulation_scheme::QAM16:
      bits_per_symbol = 4;
      break;
    case srsran::modulation_scheme::QAM64:
      bits_per_symbol = 6;
      break;
    default:
      bits_per_symbol = 8;
  }

  unsigned                  nof_expected_soft_output_bits = nof_rx_symbols_port * bits_per_symbol;
  pusch_codeword_buffer_spy sch_data(nof_expected_soft_output_bits);

  // Demodulate the PUSCH transmission.
  pusch_demodulator_notifier_spy notifier;
  demodulator->demodulate(
      sch_data.get_buffer(), notifier.get_notifier(), grid->get_reader(), chan_estimates, demodulator_config);

  // Return the results to MATLAB.
  std::vector<int8_t> sch_data_int8(sch_data.get_data().begin(), sch_data.get_data().end());
  TypedArray<int8_t> out = factory.createArray({sch_data_int8.size(), 1}, sch_data_int8.cbegin(), sch_data_int8.cend());
  outputs[0]             = out;
}
