#include "pusch_demodulator_mex.h"
#include "srsran_matlab/support/matlab_to_srs.h"

using matlab::mex::ArgumentList;
using namespace matlab::data;
using namespace srsran;
using namespace srsran_matlab;

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

void MexFunction::method_step(ArgumentList& outputs, ArgumentList& inputs)
{
  check_step_outputs_inputs(outputs, inputs);

  // Get the PUSCH demodulator configuration from MATLAB.
  StructArray                      in_struct_array = inputs[4];
  Struct                           in_dem_cfg      = in_struct_array[0];
  pusch_demodulator::configuration demodulator_config;

  // Build the RB allocation bitmask (contiguous PRB allocation is assumed).
  const TypedArray<double> rb_mask_in          = in_dem_cfg["rbMask"];
  int                      num_of_rb           = rb_mask_in.getNumberOfElements();
  int                      start_prb_index     = 0;
  int                      end_prb_index       = 0;
  bool                     start_prb_index_set = false;
  for (int rb_index = 0; rb_index != num_of_rb; ++rb_index) {
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
  const TypedArray<double>             dmrs_pos_in = in_dem_cfg["dmrsSymbPos"];
  std::array<bool, MAX_NSYMB_PER_SLOT> dmrs_symb_pos;
  for (int symb_index = 0; symb_index != MAX_NSYMB_PER_SLOT; ++symb_index) {
    dmrs_symb_pos[symb_index] = (dmrs_pos_in[symb_index] == 1) ? true : false;
  }

  // Build the placeholder RE indices list.
  const TypedArray<double> placeholders_in   = in_dem_cfg["placeholders"];
  int                      num_of_re_indices = placeholders_in.getNumberOfElements();
  ulsch_placeholder_list   placeholders;
  for (int re_index = 0; re_index != num_of_re_indices; ++re_index) {
    placeholders.push_back(placeholders_in[re_index]);
  }

  // Build the rx port list.
  const TypedArray<double>          rx_ports_in     = in_dem_cfg["rxPorts"];
  int                               num_of_rx_ports = rx_ports_in.getNumberOfElements();
  static_vector<uint8_t, MAX_PORTS> rx_ports;
  for (int rx_port = 0; rx_port != num_of_rx_ports; ++rx_port) {
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
  demodulator_config.placeholders                = placeholders;
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
        coordinate.subcarrier = in_grid_indices_array[i_re][0];
        coordinate.symbol     = in_grid_indices_array[i_re][1];
        coordinates.emplace_back(coordinate);
        values.emplace_back(rx_symbols[i_re]);
      }
    }

    // Put elements in the grid for the selected port.
    grid->put(i_port, coordinates, values);
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
  unsigned bits_per_symbol;
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

  unsigned                          nof_expected_soft_output_bits = nof_rx_symbols_port * bits_per_symbol;
  std::vector<log_likelihood_ratio> sch_data(nof_expected_soft_output_bits);

  // Demodulate the PUSCH transmission.
  demodulator->demodulate(sch_data, *grid, chan_estimates, demodulator_config);

  // Return the results to MATLAB.
  std::vector<int8_t> sch_data_int8(sch_data.cbegin(), sch_data.cend());
  TypedArray<int8_t> out = factory.createArray({sch_data_int8.size(), 1}, sch_data_int8.cbegin(), sch_data_int8.cend());
  outputs[0]             = out;
}
