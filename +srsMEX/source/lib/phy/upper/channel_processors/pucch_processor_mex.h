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
/// \brief PUCCH processor MEX declaration.

#pragma once

#include "srsran_matlab/srsran_mex_dispatcher.h"
#include "srsran/phy/generic_functions/generic_functions_factories.h"
#include "srsran/phy/upper/channel_coding/channel_coding_factories.h"
#include "srsran/phy/upper/channel_modulation/channel_modulation_factories.h"
#include "srsran/phy/upper/channel_processors/pucch/factories.h"
#include "srsran/phy/upper/channel_processors/pucch/pucch_processor.h"
#include "srsran/phy/upper/channel_processors/uci/factories.h"
#include "srsran/phy/upper/equalization/equalization_factories.h"
#include "srsran/phy/upper/sequence_generators/sequence_generator_factories.h"
#include "srsran/phy/upper/signal_processors/signal_processor_factories.h"
#include "srsran/ran/pucch/pucch_constants.h"

#include <memory>

/// \brief Factory method for a PUCCH processor.
///
/// Creates and assemblies all the necessary components (estimator, demodulator, detector, ...) for a fully-functional
/// PUCCH processor.
inline std::tuple<std::unique_ptr<srsran::pucch_processor>, std::unique_ptr<srsran::pucch_pdu_validator>>
create_pucch_processor();

/// Implements a PUCCH processor following the srsran_mex_dispatcher template.
class MexFunction : public srsran_mex_dispatcher
{
public:
  /// \brief Constructor.
  ///
  /// Stores the string identifier&ndash;method pairs that form the public interface of the PUCCH decoder MEX object.
  MexFunction()
  {
    std::tie(processor, validator) = create_pucch_processor();

    // Ensure srsRAN PUCCH processor and validator were created successfully.
    if (!processor) {
      mex_abort("Cannot create srsRAN PUCCH processor.");
    }
    if (!validator) {
      mex_abort("Cannot create srsRAN PUCCH PDU validator.");
    }

    create_callback("step", [this](ArgumentList out, ArgumentList in) { return this->method_step(out, in); });
  }

private:
  /// \brief Processes a PUCCH transmission of any format.
  ///
  /// This method reads a PUCCH from a resource grid and returns the UCI message
  /// (specifically, HARQ ACK bits, SR bits, CSI Part 1 and Part 2 bits, when applicable). Intermediate steps consist in
  /// channel estimation and equalization, detection or demodulation and decoding.
  ///
  /// The method takes three inputs.
  ///   - The string <tt>"step"</tt>.
  ///   - A resource grid, that is a two- or three-dimensional array of complex floats with the received samples
  ///     (subcarriers, OFDM symbols, antenna ports).
  ///   - A structure that provides the PUCCH configurations. The fields are
  ///      - \c Format, the PUCCH format, specifically 0, 1, 2, 3 or 4;
  ///      - \c SubcarrierSpacing, the subcarrier spacing;
  ///      - \c NSlot, slot counter (unsigned);
  ///      - \c CP, cyclic prefix (either 'normal' or 'extended');
  ///      - \c NRxPorts, number of Rx antenna ports (unsigned);
  ///      - \c NSizeBWP, number of PRBs in the bandwidth part \f$\{1,\dots,275\}\f$;
  ///      - \c NStartBWP, starting PRB index of the bandwidth part relative to CRB 0 \f$\{0,\dots,274\}\f$;
  ///      - \c StartPRB, starting PRB index, relative to the BWP, allocated to the PUCCH transmission
  ///        \f$\{0,\dots,274\}\f$;
  ///      - \c SecondHopStartPRB, starting PRB index, relative to the BWP, of the second hop \f$\{0,\dots,274\}\f$ or
  ///        set to [] if frequency offset is not used;
  ///      - \c NumPRBs, number of contiguous PRB allocated to the PUCCH transmission \f$\{1,\dots,16\}\f$ (Format 2 and
  ///      3
  ///        only);
  ///      - \c StartSymbolIndex, first OFDM symbol index in allocated to the PUCCH transmission in the slot
  ///        \f$\{0,\dots, 12\}\f$;
  ///      - \c NumOFDMSymbols, number of OFDM symbols allocated to the PUCCH transmission in the slot
  ///        \f$\{1, \dots, 14\}\f$;
  ///      - \c RNTI, radio network temporary identifier \f$\{0, \dots, 65535\}\f$ (Formats 2, 3 and 4 only);
  ///      - \c NID, PUCCH scrambling identity \f$\{0, \dots, 1023\}\f$;
  ///      - \c NID0, DM-RS scrambling identity \f$\{0, \dots, 65535\}\f$ (Format 2 only);
  ///      - \c InitialCyclicShift, initial cyclic shift \f$\{0, \dots, 11\}\f$ (Formats 0 and 1 only);
  ///      - \c OCCI, Orthogonal cover code index \f$\{0, \dots, 6\}\f$ (Formats 1 and 4 only);
  ///      - \c NumHARQAck, number of HARQ ACK bits \f$\{0, \dots, 1706\}\f$;
  ///      - \c NumSR, number of SR bits \f$\{0, \dots, 4\}\f$ (Formats 0, 2, 3 and 4 only);
  ///      - \c NumCSIPart1, number of CSI Part 1 bits \f$\{0, \dots, 1706\}\f$ (Formats 2, 3 and 4 only);
  ///      - \c NumCSIPart2, number of CSI Part 2 bits \f$\{0, \dots, 1706\}\f$ (Formats 2, 3 and 4 only).
  ///      - \c NIDHopping, hopping identity \f$\{0, \dots, 1023\}\f$ (Formats 3 and 4 only);
  ///      - \c NIDScrambling, PUCCH scrambling identity \f$\{0, \dots, 1023\}\f$ (Formats 3 and 4 only);
  ///      - \c AdditionalDMRS, additional DM-RS flag (bool) (Formats 3 and 4 only).
  ///      - \c Pi2BPSK, flag that indicates if the modulation is pi/2-bpsk (bool) (Formats 3 and 4 only).
  ///      - \c SpreadingFactor, spreading factor \f$\{2, 4\}\f$ (Format 4 only).
  ///
  /// The method has five outputs.
  ///   - A string reporting the status of the message {'valid', 'invalid', 'unknown'}.
  ///   - An array of binary values corresponding to the HARQ ACK bits.
  ///   - An array of binary values corresponding to the SR bits.
  ///   - An array of binary values corresponding to the CSI Part 1 bits.
  ///   - An array of binary values corresponding to the CSI Part 2 bits.
  ///
  /// \remark Any of the bit arrays can be replaced with the scalar value 9 to denote an empty array.
  void method_step(ArgumentList outputs, ArgumentList inputs);
  /// Checks that outputs/inputs arguments match the requirements of method_step().
  void check_step_outputs_inputs(ArgumentList outputs, ArgumentList inputs);
  /// \brief Fills a TypedArray with the bits in the \c field span.
  ///
  /// \remark If \c field is empty, the function returns the \f$1 \times 1\f$ array \f$[9]\f$.
  matlab::data::TypedArray<uint8_t> fill_message_fields(srsran::span<const uint8_t> field);

  /// A pointer to the actual PUCCH processor.
  std::unique_ptr<srsran::pucch_processor> processor;
  /// A pointer to the PUCCH PDU validator.
  std::unique_ptr<srsran::pucch_pdu_validator> validator;
};

std::tuple<std::unique_ptr<srsran::pucch_processor>, std::unique_ptr<srsran::pucch_pdu_validator>>
create_pucch_processor()
{
  using namespace srsran;

  std::shared_ptr<pseudo_random_generator_factory>     prg_factory = create_pseudo_random_generator_sw_factory();
  std::shared_ptr<low_papr_sequence_generator_factory> lpapr_generator_factory =
      create_low_papr_sequence_generator_sw_factory();
  std::shared_ptr<low_papr_sequence_collection_factory> lpapr_collection_factory =
      create_low_papr_sequence_collection_sw_factory(lpapr_generator_factory);
  std::shared_ptr<dft_processor_factory>            dft_factory = create_dft_processor_factory_fftw_slow();
  std::shared_ptr<time_alignment_estimator_factory> ta_est_factory =
      create_time_alignment_estimator_dft_factory(dft_factory);
  std::shared_ptr<port_channel_estimator_factory> estimator_factory =
      create_port_channel_estimator_factory_sw(ta_est_factory);
  std::shared_ptr<dmrs_pucch_estimator_factory> dmrs_factory = create_dmrs_pucch_estimator_factory_sw(
      prg_factory, lpapr_collection_factory, lpapr_generator_factory, estimator_factory);
  std::shared_ptr<transform_precoder_factory> precoding_factory =
      create_dft_transform_precoder_factory(dft_factory, pucch_constants::FORMAT3_MAX_NPRB + 1);

  std::shared_ptr<channel_equalizer_factory> equalizer_factory =
      create_channel_equalizer_generic_factory(channel_equalizer_algorithm_type::zf);
  std::shared_ptr<pucch_detector_factory> detector_factory =
      create_pucch_detector_factory_sw(lpapr_collection_factory, prg_factory, equalizer_factory);

  std::shared_ptr<demodulation_mapper_factory> demodulation_factory = create_demodulation_mapper_factory();
  std::shared_ptr<pucch_demodulator_factory>   demodulator_factory =
      create_pucch_demodulator_factory_sw(equalizer_factory, demodulation_factory, prg_factory, precoding_factory);

  std::shared_ptr<short_block_detector_factory> short_block_dec_factory = create_short_block_detector_factory_sw();
  std::shared_ptr<polar_factory>                polar_dec_factory       = create_polar_factory_sw();
  std::shared_ptr<crc_calculator_factory>       crc_calc_factory        = create_crc_calculator_factory_sw("auto");
  std::shared_ptr<uci_decoder_factory>          uci_dec_factory =
      create_uci_decoder_factory_generic(short_block_dec_factory, polar_dec_factory, crc_calc_factory);

  channel_estimate::channel_estimate_dimensions channel_estimate_dimensions;
  channel_estimate_dimensions.nof_tx_layers = 1;
  channel_estimate_dimensions.nof_rx_ports  = 4;
  channel_estimate_dimensions.nof_symbols   = MAX_NSYMB_PER_SLOT;
  channel_estimate_dimensions.nof_prb       = MAX_RB;

  std::shared_ptr<pucch_processor_factory> processor_factory = create_pucch_processor_factory_sw(
      dmrs_factory, detector_factory, demodulator_factory, uci_dec_factory, channel_estimate_dimensions);

  return {processor_factory->create(), processor_factory->create_validator()};
}
