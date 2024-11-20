/*
 *
 * Copyright 2021-2024 Software Radio Systems Limited
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

#include "pucch_processor_mex.h"
#include "srsran_matlab/support/matlab_to_srs.h"
#include "srsran_matlab/support/resource_grid.h"
#include "srsran/phy/support/resource_grid_writer.h"
#include <optional>

using namespace matlab::data;
using namespace srsran;
using namespace srsran_matlab;

void MexFunction::check_step_outputs_inputs(ArgumentList outputs, ArgumentList inputs)
{
  constexpr unsigned NOF_INPUTS = 3;
  if (inputs.size() != NOF_INPUTS) {
    mex_abort("Wrong number of inputs: expected {}, provided {}.", NOF_INPUTS, inputs.size());
  }

  ArrayDimensions in1_dims = inputs[1].getDimensions();
  if ((inputs[1].getType() != ArrayType::COMPLEX_SINGLE) || (in1_dims.size() < 2) || (in1_dims.size() > 3)) {
    mex_abort("Input 'rxGrid' should be a 2- or 3-dimensional array of complex floats, provided [{}].", in1_dims);
  }

  if ((inputs[2].getType() != ArrayType::STRUCT) || (inputs[2].getNumberOfElements() > 1)) {
    mex_abort("Input 'config' should be a scalar structure.");
  }

  constexpr unsigned NOF_OUTPUTS = 5;
  if (outputs.size() != NOF_OUTPUTS) {
    mex_abort("Wrong number of outputs: expected {}, provided {}.", NOF_OUTPUTS, outputs.size());
  }
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

static pucch_processor::format0_configuration populate_f0_configuration(const Struct& in_cfg)
{
  // Create a PUCCH F0 configuration object.
  pucch_processor::format0_configuration cfg = {};

  cfg.context = std::nullopt;

  // Set the slot point.
  unsigned scs_kHz    = in_cfg["SubcarrierSpacing"][0];
  unsigned slot_count = in_cfg["NSlot"][0];
  cfg.slot            = {matlab_to_srs_subcarrier_spacing(scs_kHz), slot_count};

  // Set the cyclic prefix.
  const CharArray in_cp = in_cfg["CP"];
  cfg.cp                = matlab_to_srs_cyclic_prefix(in_cp.toAscii());

  // Set the port indices.
  unsigned nof_ports = in_cfg["NRxPorts"][0];
  cfg.ports.clear();
  for (unsigned i_port = 0; i_port != nof_ports; ++i_port) {
    cfg.ports.push_back(i_port);
  }

  // Set the BWP.
  cfg.bwp_size_rb  = static_cast<unsigned>(in_cfg["NSizeBWP"][0]);
  cfg.bwp_start_rb = static_cast<unsigned>(in_cfg["NStartBWP"][0]);

  // Set the frequency allocation.
  cfg.starting_prb   = static_cast<unsigned>(in_cfg["StartPRB"][0]);
  cfg.second_hop_prb = std::nullopt;
  if (!in_cfg["SecondHopStartPRB"].isEmpty()) {
    cfg.second_hop_prb = static_cast<unsigned>(in_cfg["SecondHopStartPRB"][0]);
  }

  // Set the time allocation.
  cfg.start_symbol_index = static_cast<unsigned>(in_cfg["StartSymbolIndex"][0]);
  cfg.nof_symbols        = static_cast<unsigned>(in_cfg["NumOFDMSymbols"][0]);

  // Set the initial cyclic shift.
  cfg.initial_cyclic_shift = static_cast<unsigned>(in_cfg["InitialCyclicShift"][0]);

  // Set the scrambling identifier.
  cfg.n_id = static_cast<unsigned>(in_cfg["NID"][0]);

  // Set the lengths of UCI fields.
  cfg.nof_harq_ack = static_cast<unsigned>(in_cfg["NumHARQAck"][0]);

  // Set the SR opportunity.
  cfg.sr_opportunity = (static_cast<unsigned>(in_cfg["NumSR"][0]) == 1);

  return cfg;
}

static pucch_processor::format1_configuration populate_f1_configuration(const Struct& in_cfg)
{
  // Create a PUCCH F1 configuration object.
  pucch_processor::format1_configuration cfg = {};

  cfg.context = std::nullopt;

  // Set the slot point.
  unsigned scs_kHz    = in_cfg["SubcarrierSpacing"][0];
  unsigned slot_count = in_cfg["NSlot"][0];
  cfg.slot            = {matlab_to_srs_subcarrier_spacing(scs_kHz), slot_count};

  // Set the cyclic prefix.
  const CharArray in_cp = in_cfg["CP"];
  cfg.cp                = matlab_to_srs_cyclic_prefix(in_cp.toAscii());

  // Set the port indices.
  unsigned nof_ports = in_cfg["NRxPorts"][0];
  cfg.ports.clear();
  for (unsigned i_port = 0; i_port != nof_ports; ++i_port) {
    cfg.ports.push_back(i_port);
  }

  // Set the BWP.
  cfg.bwp_size_rb  = static_cast<unsigned>(in_cfg["NSizeBWP"][0]);
  cfg.bwp_start_rb = static_cast<unsigned>(in_cfg["NStartBWP"][0]);

  // Set the frequency allocation.
  cfg.starting_prb   = static_cast<unsigned>(in_cfg["StartPRB"][0]);
  cfg.second_hop_prb = std::nullopt;
  if (!in_cfg["SecondHopStartPRB"].isEmpty()) {
    cfg.second_hop_prb = static_cast<unsigned>(in_cfg["SecondHopStartPRB"][0]);
  }

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

  return cfg;
}

static pucch_processor::format2_configuration populate_f2_configuration(const Struct& in_cfg)
{
  // Create a PUCCH F2 configuration object.
  pucch_processor::format2_configuration cfg = {};

  cfg.context = std::nullopt;

  // Set the slot point.
  unsigned scs_kHz    = in_cfg["SubcarrierSpacing"][0];
  unsigned slot_count = in_cfg["NSlot"][0];
  cfg.slot            = {matlab_to_srs_subcarrier_spacing(scs_kHz), slot_count};

  // Set the cyclic prefix.
  const CharArray in_cp = in_cfg["CP"];
  cfg.cp                = matlab_to_srs_cyclic_prefix(in_cp.toAscii());

  // Set the port indices.
  unsigned nof_ports = in_cfg["NRxPorts"][0];
  cfg.ports.clear();
  for (unsigned i_port = 0; i_port != nof_ports; ++i_port) {
    cfg.ports.push_back(i_port);
  }

  // Set the BWP.
  cfg.bwp_size_rb  = static_cast<unsigned>(in_cfg["NSizeBWP"][0]);
  cfg.bwp_start_rb = static_cast<unsigned>(in_cfg["NStartBWP"][0]);

  // Set the frequency allocation.
  cfg.starting_prb   = static_cast<unsigned>(in_cfg["StartPRB"][0]);
  cfg.nof_prb        = static_cast<unsigned>(in_cfg["NumPRBs"][0]);
  cfg.second_hop_prb = std::nullopt;
  if (!in_cfg["SecondHopStartPRB"].isEmpty()) {
    cfg.second_hop_prb = static_cast<unsigned>(in_cfg["SecondHopStartPRB"][0]);
  }

  // Set the time allocation.
  cfg.start_symbol_index = static_cast<unsigned>(in_cfg["StartSymbolIndex"][0]);
  cfg.nof_symbols        = static_cast<unsigned>(in_cfg["NumOFDMSymbols"][0]);

  // Set the RNTI.
  cfg.rnti = static_cast<unsigned>(in_cfg["RNTI"][0]);

  // Set the scrambling identifier.
  cfg.n_id = static_cast<unsigned>(in_cfg["NID"][0]);

  // Set the DM-RS scrambling identifier.
  cfg.n_id_0 = static_cast<unsigned>(in_cfg["NID0"][0]);

  // Set the lengths of UCI fields.
  cfg.nof_harq_ack  = static_cast<unsigned>(in_cfg["NumHARQAck"][0]);
  cfg.nof_sr        = static_cast<unsigned>(in_cfg["NumSR"][0]);
  cfg.nof_csi_part1 = static_cast<unsigned>(in_cfg["NumCSIPart1"][0]);
  cfg.nof_csi_part2 = static_cast<unsigned>(in_cfg["NumCSIPart2"][0]);

  return cfg;
}

static pucch_processor::format3_configuration populate_f3_configuration(const Struct& in_cfg)
{
  // Create a PUCCH F3 configuration object.
  pucch_processor::format3_configuration cfg = {};

  cfg.context = std::nullopt;

  // Set the slot point.
  unsigned scs_kHz    = in_cfg["SubcarrierSpacing"][0];
  unsigned slot_count = in_cfg["NSlot"][0];
  cfg.slot            = {matlab_to_srs_subcarrier_spacing(scs_kHz), slot_count};

  // Set the cyclic prefix.
  const CharArray in_cp = in_cfg["CP"];
  cfg.cp                = matlab_to_srs_cyclic_prefix(in_cp.toAscii());

  // Set the port indices.
  unsigned nof_ports = in_cfg["NRxPorts"][0];
  cfg.ports.clear();
  for (unsigned i_port = 0; i_port != nof_ports; ++i_port) {
    cfg.ports.push_back(i_port);
  }

  // Set the BWP.
  cfg.bwp_size_rb  = static_cast<unsigned>(in_cfg["NSizeBWP"][0]);
  cfg.bwp_start_rb = static_cast<unsigned>(in_cfg["NStartBWP"][0]);

  // Set the frequency allocation.
  cfg.starting_prb   = static_cast<unsigned>(in_cfg["StartPRB"][0]);
  cfg.nof_prb        = static_cast<unsigned>(in_cfg["NumPRBs"][0]);
  cfg.second_hop_prb = std::nullopt;
  if (!in_cfg["SecondHopStartPRB"].isEmpty()) {
    cfg.second_hop_prb = static_cast<unsigned>(in_cfg["SecondHopStartPRB"][0]);
  }

  // Set the time allocation.
  cfg.start_symbol_index = static_cast<unsigned>(in_cfg["StartSymbolIndex"][0]);
  cfg.nof_symbols        = static_cast<unsigned>(in_cfg["NumOFDMSymbols"][0]);

  // Set the RNTI.
  cfg.rnti = static_cast<unsigned>(in_cfg["RNTI"][0]);

  // Set the hopping identifier.
  cfg.n_id_hopping = static_cast<unsigned>(in_cfg["NIDHopping"][0]);

  // Set the scrambling identifier.
  cfg.n_id_scrambling = static_cast<unsigned>(in_cfg["NIDScrambling"][0]);

  cfg.additional_dmrs = static_cast<bool>(in_cfg["AdditionalDMRS"][0]);
  cfg.pi2_bpsk        = static_cast<bool>(in_cfg["Pi2BPSK"][0]);

  // Set the lengths of UCI fields.
  cfg.nof_harq_ack  = static_cast<unsigned>(in_cfg["NumHARQAck"][0]);
  cfg.nof_sr        = static_cast<unsigned>(in_cfg["NumSR"][0]);
  cfg.nof_csi_part1 = static_cast<unsigned>(in_cfg["NumCSIPart1"][0]);
  cfg.nof_csi_part2 = static_cast<unsigned>(in_cfg["NumCSIPart2"][0]);

  return cfg;
}

static pucch_processor::format4_configuration populate_f4_configuration(const Struct& in_cfg)
{
  // Create a PUCCH F4 configuration object.
  pucch_processor::format4_configuration cfg = {};

  cfg.context = std::nullopt;

  // Set the slot point.
  unsigned scs_kHz    = in_cfg["SubcarrierSpacing"][0];
  unsigned slot_count = in_cfg["NSlot"][0];
  cfg.slot            = {matlab_to_srs_subcarrier_spacing(scs_kHz), slot_count};

  // Set the cyclic prefix.
  const CharArray in_cp = in_cfg["CP"];
  cfg.cp                = matlab_to_srs_cyclic_prefix(in_cp.toAscii());

  // Set the port indices.
  unsigned nof_ports = in_cfg["NRxPorts"][0];
  cfg.ports.clear();
  for (unsigned i_port = 0; i_port != nof_ports; ++i_port) {
    cfg.ports.push_back(i_port);
  }

  // Set the BWP.
  cfg.bwp_size_rb  = static_cast<unsigned>(in_cfg["NSizeBWP"][0]);
  cfg.bwp_start_rb = static_cast<unsigned>(in_cfg["NStartBWP"][0]);

  // Set the frequency allocation.
  cfg.starting_prb   = static_cast<unsigned>(in_cfg["StartPRB"][0]);
  cfg.second_hop_prb = std::nullopt;
  if (!in_cfg["SecondHopStartPRB"].isEmpty()) {
    cfg.second_hop_prb = static_cast<unsigned>(in_cfg["SecondHopStartPRB"][0]);
  }

  // Set the time allocation.
  cfg.start_symbol_index = static_cast<unsigned>(in_cfg["StartSymbolIndex"][0]);
  cfg.nof_symbols        = static_cast<unsigned>(in_cfg["NumOFDMSymbols"][0]);

  // Set the RNTI.
  cfg.rnti = static_cast<unsigned>(in_cfg["RNTI"][0]);

  // Set the hopping identifier.
  cfg.n_id_hopping = static_cast<unsigned>(in_cfg["NIDHopping"][0]);

  // Set the scrambling identifier.
  cfg.n_id_scrambling = static_cast<unsigned>(in_cfg["NIDScrambling"][0]);

  cfg.additional_dmrs = static_cast<bool>(in_cfg["AdditionalDMRS"][0]);
  cfg.pi2_bpsk        = static_cast<bool>(in_cfg["Pi2BPSK"][0]);

  cfg.occ_index  = static_cast<unsigned>(in_cfg["OCCI"][0]);
  cfg.occ_length = static_cast<unsigned>(in_cfg["SpreadingFactor"][0]);

  // Set the lengths of UCI fields.
  cfg.nof_harq_ack  = static_cast<unsigned>(in_cfg["NumHARQAck"][0]);
  cfg.nof_sr        = static_cast<unsigned>(in_cfg["NumSR"][0]);
  cfg.nof_csi_part1 = static_cast<unsigned>(in_cfg["NumCSIPart1"][0]);
  cfg.nof_csi_part2 = static_cast<unsigned>(in_cfg["NumCSIPart2"][0]);

  return cfg;
}

void MexFunction::method_step(ArgumentList outputs, ArgumentList inputs)
{
  check_step_outputs_inputs(outputs, inputs);

  // Read the resource grid from inputs[1].
  std::unique_ptr<resource_grid> grid = read_resource_grid(inputs[1]);
  if (!grid) {
    mex_abort("Cannot create resource grid.");
  }

  // Read the configuration structure.
  StructArray  in_cfg_array = inputs[2];
  const Struct in_cfg       = in_cfg_array[0];

  // Prepare result container.
  pucch_processor_result result;

  unsigned pucch_format = in_cfg["Format"][0];

  switch (pucch_format) {
    case 0: {
      unsigned nof_sr = in_cfg["NumSR"][0];
      if (nof_sr > 1) {
        mex_abort("For PUCCH Format 0 the number of SR bits is at most one, given {}.", nof_sr);
      }

      const pucch_processor::format0_configuration cfg = populate_f0_configuration(in_cfg);

      // Ensure the provided configuration is valid.
      error_type<std::string> validation = validator->is_valid(cfg);
      if (!validation.has_value()) {
        mex_abort(fmt::format("The provided PUCCH Format 0 configuration is invalid: {}\n", validation.error()));
      }

      unsigned nof_conf_grid_ports = cfg.ports.size();
      unsigned nof_grid_ports      = grid->get_writer().get_nof_ports();
      if (nof_conf_grid_ports != nof_grid_ports) {
        mex_abort(
            "Field NRxPorts in the configuration structure and the number of resource grid ports do not match: {} "
            "vs. {}.",
            nof_conf_grid_ports,
            nof_grid_ports);
      }

      // Run the PUCCH processor.
      result = processor->process(grid->get_reader(), cfg);
      break;
    }
    case 1: {
      const pucch_processor::format1_configuration cfg = populate_f1_configuration(in_cfg);

      // Ensure the provided configuration is valid.
      error_type<std::string> validation = validator->is_valid(cfg);
      if (!validation.has_value()) {
        mex_abort(fmt::format("The provided PUCCH Format 1 configuration is invalid: {}\n", validation.error()));
      }

      unsigned nof_conf_grid_ports = cfg.ports.size();
      unsigned nof_grid_ports      = grid->get_writer().get_nof_ports();
      if (nof_conf_grid_ports != nof_grid_ports) {
        mex_abort(
            "Field NRxPorts in the configuration structure and the number of resource grid ports do not match: {} "
            "vs. {}.",
            nof_conf_grid_ports,
            nof_grid_ports);
      }

      // Run the PUCCH processor.
      result = processor->process(grid->get_reader(), cfg);
      break;
    }
    case 2: {
      const pucch_processor::format2_configuration cfg = populate_f2_configuration(in_cfg);

      // Ensure the provided configuration is valid.
      error_type<std::string> validation = validator->is_valid(cfg);
      if (!validation.has_value()) {
        mex_abort(fmt::format("The provided PUCCH Format 2 configuration is invalid: {}\n", validation.error()));
      }

      unsigned nof_conf_grid_ports = cfg.ports.size();
      unsigned nof_grid_ports      = grid->get_writer().get_nof_ports();
      if (nof_conf_grid_ports != nof_grid_ports) {
        mex_abort(
            "Field NRxPorts in the configuration structure and the number of resource grid ports do not match: {} "
            "vs. {}.",
            nof_conf_grid_ports,
            nof_grid_ports);
      }

      // Run the PUCCH processor.
      result = processor->process(grid->get_reader(), cfg);
      break;
    }
    case 3: {
      const pucch_processor::format3_configuration cfg = populate_f3_configuration(in_cfg);

      // Ensure the provided configuration is valid.
      error_type<std::string> validation = validator->is_valid(cfg);
      if (!validation.has_value()) {
        mex_abort(fmt::format("The provided PUCCH Format 3 configuration is invalid: {}\n", validation.error()));
      }

      unsigned nof_conf_grid_ports = cfg.ports.size();
      unsigned nof_grid_ports      = grid->get_writer().get_nof_ports();
      if (nof_conf_grid_ports != nof_grid_ports) {
        mex_abort(
            "Field NRxPorts in the configuration structure and the number of resource grid ports do not match: {} "
            "vs. {}.",
            nof_conf_grid_ports,
            nof_grid_ports);
      }

      // Run the PUCCH processor.
      result = processor->process(grid->get_reader(), cfg);
      break;
    }
    case 4: {
      const pucch_processor::format4_configuration cfg = populate_f4_configuration(in_cfg);

      // Ensure the provided configuration is valid.
      error_type<std::string> validation = validator->is_valid(cfg);
      if (!validation.has_value()) {
        mex_abort(fmt::format("The provided PUCCH Format 4 configuration is invalid: {}\n", validation.error()));
      }

      unsigned nof_conf_grid_ports = cfg.ports.size();
      unsigned nof_grid_ports      = grid->get_writer().get_nof_ports();
      if (nof_conf_grid_ports != nof_grid_ports) {
        mex_abort(
            "Field NRxPorts in the configuration structure and the number of resource grid ports do not match: {} "
            "vs. {}.",
            nof_conf_grid_ports,
            nof_grid_ports);
      }

      // Run the PUCCH processor.
      result = processor->process(grid->get_reader(), cfg);
      break;
    }
    default:
      mex_abort("Unsupported or unkown PUCCH Format {}", pucch_format);
      break;
  }

  CharArray           status        = factory.createCharArray(srsran::to_string(result.message.get_status()));
  TypedArray<uint8_t> harq_ack_bits = fill_message_fields(result.message.get_harq_ack_bits());
  TypedArray<uint8_t> sr_bits       = fill_message_fields(result.message.get_sr_bits());
  TypedArray<uint8_t> csi1_bits     = fill_message_fields(result.message.get_csi_part1_bits());
  TypedArray<uint8_t> csi2_bits     = fill_message_fields(result.message.get_csi_part2_bits());

  outputs[0] = status;
  outputs[1] = harq_ack_bits;
  outputs[2] = sr_bits;
  outputs[3] = csi1_bits;
  outputs[4] = csi2_bits;
}
