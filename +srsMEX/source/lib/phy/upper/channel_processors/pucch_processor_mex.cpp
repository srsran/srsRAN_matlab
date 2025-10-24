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
  constexpr unsigned NOF_INPUTS = 4;
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

  if (!inputs[3].isEmpty() && (inputs[3].getType() != ArrayType::STRUCT)) {
    mex_abort("Input 'MuxFormat1' should be a structure array.");
  }

  constexpr unsigned NOF_OUTPUTS = 1;
  if (outputs.size() != NOF_OUTPUTS) {
    mex_abort("Wrong number of outputs: expected {}, provided {}.", NOF_OUTPUTS, outputs.size());
  }
}

TypedArray<int8_t> MexFunction::fill_message_fields(span<const uint8_t> field)
{
  if (field.empty()) {
    // The MEX API seems to have some issue when returning an empty array. Since this is a binary array, we use 9 as a
    // tag.
    return factory.createArray<int8_t>({0, 1});
  }

  unsigned           nof_bits = field.size();
  TypedArray<int8_t> out      = factory.createArray<int8_t>({nof_bits, 1});
  for (unsigned i_bit = 0; i_bit != nof_bits; ++i_bit) {
    out[i_bit] = static_cast<int8_t>(field[i_bit]);
  }
  return out;
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

StructArray
MexFunction::call_processor(const resource_grid_reader& grid_reader, const Struct& in_cfg, const StructArray& mux_f1)
{
  unsigned pucch_format = in_cfg["Format"][0];
  if ((pucch_format == 1) && !mux_f1.isEmpty()) {
    pucch_processor::format1_configuration       cfg = populate_f1_configuration(in_cfg);
    pucch_processor::format1_batch_configuration batch_config(cfg);
    batch_config.entries.clear();

    for (const auto& this_f1 : mux_f1) {
      unsigned ics               = this_f1["InitialCyclicShift"][0];
      unsigned occi              = this_f1["OCCI"][0];
      uint16_t nof_harq_ack_bits = this_f1["NumBits"][0];

      cfg.initial_cyclic_shift = ics;
      cfg.time_domain_occ      = occi;
      cfg.nof_harq_ack         = nof_harq_ack_bits;

      // Ensure the provided configuration is valid.
      error_type<std::string> validation = validator->is_valid(cfg);
      if (!validation.has_value()) {
        mex_abort("The provided PUCCH Format 1 configuration is invalid: {}", validation.error());
      }

      if (batch_config.entries.contains(ics, occi)) {
        mex_abort("The F1 multiplexed list contains duplicated entries for ICS {} and OCCI {}.", ics, occi);
      }
      batch_config.entries.insert(ics, occi, {.context = {}, .nof_harq_ack = nof_harq_ack_bits});
    }

    // Run the PUCCH processor.
    const auto& batch_results = processor->process(grid_reader, batch_config);

    unsigned nof_pucchs = batch_results.size();
    if (nof_pucchs != mux_f1.getNumberOfElements()) {
      mex_abort("The number of processed PUCCH F1 transmsissions {} does not match the configured ones {}.",
                nof_pucchs,
                mux_f1.getNumberOfElements());
    }

    StructArray out = factory.createStructArray(
        {nof_pucchs, 1},
        {"InitialCyclicShift", "OCCI", "isValid", "HARQAckPayload", "SRPayload", "CSI1Payload", "CSI2Payload"});
    unsigned i_pucch = 0;
    for (const auto& this_f1 : mux_f1) {
      unsigned ics  = this_f1["InitialCyclicShift"][0];
      unsigned occi = this_f1["OCCI"][0];

      if (!batch_results.contains(ics, occi)) {
        mex_abort("PUCCH ({}, {}) is configured but not processed.", ics, occi);
      }
      const pucch_processor_result& result = batch_results.get(ics, occi);
      out[i_pucch]["InitialCyclicShift"]   = factory.createScalar<double>(ics);
      out[i_pucch]["OCCI"]                 = factory.createScalar<double>(occi);
      out[i_pucch]["isValid"]              = factory.createScalar(result.message.get_status() == uci_status::valid);
      out[i_pucch]["HARQAckPayload"]       = fill_message_fields(result.message.get_harq_ack_bits());
      out[i_pucch]["SRPayload"]            = fill_message_fields(result.message.get_sr_bits());
      out[i_pucch]["CSI1Payload"]          = fill_message_fields(result.message.get_csi_part1_bits());
      out[i_pucch++]["CSI2Payload"]        = fill_message_fields(result.message.get_csi_part2_bits());
    }

    return out;
  }

  // Prepare result container.
  pucch_processor_result result;

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
        mex_abort("The provided PUCCH Format 0 configuration is invalid: {}.", validation.error());
      }

      // Run the PUCCH processor.
      result = processor->process(grid_reader, cfg);
      break;
    }
    case 1: {
      const pucch_processor::format1_configuration cfg = populate_f1_configuration(in_cfg);

      // Ensure the provided configuration is valid.
      error_type<std::string> validation = validator->is_valid(cfg);
      if (!validation.has_value()) {
        mex_abort("The provided PUCCH Format 1 configuration is invalid: {}.", validation.error());
      }

      // Run the PUCCH processor.
      pucch_processor::format1_batch_configuration batch_config(cfg);
      const auto&                                  batch_results = processor->process(grid_reader, batch_config);
      result = batch_results.get(cfg.initial_cyclic_shift, cfg.time_domain_occ);
      break;
    }
    case 2: {
      const pucch_processor::format2_configuration cfg = populate_f2_configuration(in_cfg);

      // Ensure the provided configuration is valid.
      error_type<std::string> validation = validator->is_valid(cfg);
      if (!validation.has_value()) {
        mex_abort("The provided PUCCH Format 2 configuration is invalid: {}.", validation.error());
      }

      // Run the PUCCH processor.
      result = processor->process(grid_reader, cfg);
      break;
    }
    case 3: {
      const pucch_processor::format3_configuration cfg = populate_f3_configuration(in_cfg);

      // Ensure the provided configuration is valid.
      error_type<std::string> validation = validator->is_valid(cfg);
      if (!validation.has_value()) {
        mex_abort("The provided PUCCH Format 3 configuration is invalid: {}.", validation.error());
      }

      // Run the PUCCH processor.
      result = processor->process(grid_reader, cfg);
      break;
    }
    case 4: {
      const pucch_processor::format4_configuration cfg = populate_f4_configuration(in_cfg);

      // Ensure the provided configuration is valid.
      error_type<std::string> validation = validator->is_valid(cfg);
      if (!validation.has_value()) {
        mex_abort("The provided PUCCH Format 4 configuration is invalid: {}.", validation.error());
      }

      // Run the PUCCH processor.
      result = processor->process(grid_reader, cfg);
      break;
    }
    default:
      mex_abort("Unsupported or unkown PUCCH Format {}", pucch_format);
      break;
  }

  StructArray out =
      factory.createStructArray({1, 1}, {"isValid", "HARQAckPayload", "SRPayload", "CSI1Payload", "CSI2Payload"});
  out[0]["isValid"]        = factory.createScalar(result.message.get_status() == uci_status::valid);
  out[0]["HARQAckPayload"] = fill_message_fields(result.message.get_harq_ack_bits());
  out[0]["SRPayload"]      = fill_message_fields(result.message.get_sr_bits());
  out[0]["CSI1Payload"]    = fill_message_fields(result.message.get_csi_part1_bits());
  out[0]["CSI2Payload"]    = fill_message_fields(result.message.get_csi_part2_bits());

  return out;
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
  StructArray             in_cfg_array = inputs[2];
  const Reference<Struct> in_cfg       = in_cfg_array[0];

  unsigned    pucch_format = in_cfg["Format"][0];
  StructArray mux_f1 =
      (inputs[3].isEmpty() ? factory.createStructArray({0, 0}, {"InitialCyclicShift", "OCCI", "NumBits"}) : inputs[3]);
  if ((pucch_format != 1) && (!mux_f1.isEmpty())) {
    mex_abort("For PUCCH Format {}, input 'MuxFormat1' should be empty.", pucch_format);
  }

  unsigned nof_conf_grid_ports = in_cfg["NRxPorts"][0];
  unsigned nof_grid_ports      = grid->get_writer().get_nof_ports();
  if (nof_conf_grid_ports != nof_grid_ports) {
    mex_abort("Field NRxPorts in the configuration structure and the number of resource grid ports do not match: {} "
              "vs. {}.",
              nof_conf_grid_ports,
              nof_grid_ports);
  }

  StructArray out = call_processor(grid->get_reader(), in_cfg, mux_f1);
  outputs[0]      = out;
}
