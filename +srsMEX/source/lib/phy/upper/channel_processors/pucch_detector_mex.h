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

/// \file
/// \brief PUCCH detector MEX declaration.

#pragma once

#include "srsran_matlab/srsran_mex_dispatcher.h"
#include "srsran/phy/upper/channel_processors/channel_processor_factories.h"
#include "srsran/phy/upper/channel_processors/pucch_detector.h"
#include "srsran/phy/upper/equalization/equalization_factories.h"
#include "srsran/phy/upper/sequence_generators/sequence_generator_factories.h"

/// \brief Factory method for a PUCCH processor.
///
/// Creates and assemblies all the necessary components (sequence generators, equalizer, ...) for a fully-functional
/// PUCCH detector.
inline std::unique_ptr<srsran::pucch_detector> create_pucch_detector();

/// Implements a PUCCH detector following the srsran_mex_dispatcher template.
class MexFunction : public srsran_mex_dispatcher
{
public:
  MexFunction()
  {
    if (!detector) {
      mex_abort("Cannot create srsRAN PUCCH detector.");
    }

    create_callback("step", [this](ArgumentList out, ArgumentList in) { return this->method_step(out, in); });
  }

private:
  /// \brief Detects a PUCCH Format 1 transmission.
  ///
  /// This method reads a PUCCH Format 1 from a resource grid and returns the UCI message (specifically, HARQ ACK bits,
  /// and SR bits). Specifically, it carries out channel equalization and PUCCH detection.
  ///
  /// The method takes five inputs.
  ///   - The string <tt>"step"</tt>.
  ///   - A resource grid, that is a two- or three-dimensional array of complex floats with the received samples
  ///     (subcarriers, OFDM symbols, antenna ports).
  ///   - A channel estimate, that is a two- or three-dimensional array of complex floats with the estimated channel
  ///     coefficients (must have the same number of subcarriers, OFDM symbols, antenna ports as the resource grid).
  ///   - The estimated noise variance as a nonnegative float.
  ///   - A structure that provides the PUCCH Format 1 configurations. The fields are
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
  ///      - \c StartSymbolIndex, first OFDM symbol index in allocated to the PUCCH transmission in the slot
  ///        \f$\{0,\dots, 10\}\f$;
  ///      - \c NumOFDMSymbols, number of OFDM symbols allocated to the PUCCH transmission in the slot
  ///        \f$\{1, \dots, 14\}\f$;
  ///      - \c NID, PUCCH scrambling identity \f$\{0, \dots, 1023\}\f$;
  ///      - \c InitialCyclicShift, the initial cyclic shift \f$\{0, \dots, 11\}\f$;
  ///      - \c OCCI, the orthogonal cover code index \f$\{0, \dots, 6\}\f$;
  ///      - \c Beta, the DM-RS-to-data amplitude scaling factor as a linear, nonnegative float;
  ///      - \c NumHARQAck, number of HARQ ACK bits \f$\{0, \dots, 2\}\f$.
  /// The method has three outputs.
  ///   - A string reporting the status of the message {'valid', 'invalid', 'unknown'}.
  ///   - An array of binary values corresponding to the HARQ ACK bits.
  ///   - An array of binary values corresponding to the SR bits.
  ///
  /// \remark Any of the bit arrays can be replaced with the scalar value 9 to denote an empty array.
  void method_step(ArgumentList outputs, ArgumentList inputs);

  /// Checks that outputs/inputs arguments match the requirements of method_step().
  void check_step_outputs_inputs(ArgumentList outputs, ArgumentList inputs);

  /// \brief Fills a TypedArray with the bits in the \c field span.
  ///
  /// \remark If \c field is empty, the function returns the \f$1 \times 1\f$ array \f$[9]\f$.
  matlab::data::TypedArray<uint8_t> fill_message_fields(srsran::span<const uint8_t> field);

  /// Container for channel estimates.
  srsran::channel_estimate ch_est = {};

  /// A pointer to the actual PUCCH detector.
  std::unique_ptr<srsran::pucch_detector> detector = create_pucch_detector();
};

std::unique_ptr<srsran::pucch_detector> create_pucch_detector()
{
  using namespace srsran;

  std::shared_ptr<pseudo_random_generator_factory>     prg_factory = create_pseudo_random_generator_sw_factory();
  std::shared_ptr<low_papr_sequence_generator_factory> lpapr_generator_factory =
      create_low_papr_sequence_generator_sw_factory();
  std::shared_ptr<low_papr_sequence_collection_factory> lpapr_collection_factory =
      create_low_papr_sequence_collection_sw_factory(lpapr_generator_factory);

  std::shared_ptr<channel_equalizer_factory> equalizer_factory = create_channel_equalizer_factory_zf();
  std::shared_ptr<pucch_detector_factory>    detector_factory =
      create_pucch_detector_factory_sw(lpapr_collection_factory, prg_factory, equalizer_factory);

  return detector_factory->create();
}
