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

/// \file
/// \brief PUSCH demodulator MEX declaration.

#pragma once

#include "srsran_matlab/srsran_mex_dispatcher.h"
#include "srsran/phy/support/resource_grid_writer.h"
#include "srsran/phy/support/support_factories.h"
#include "srsran/phy/upper/channel_processors/channel_processor_factories.h"
#include "srsran/phy/upper/channel_processors/pusch/pusch_demodulator.h"
#include "srsran/phy/upper/equalization/equalization_factories.h"
#include "srsran/ran/frame_types.h"

/// \brief Factory method for a PUSCH demodulator.
///
/// Creates and assemblies all the necessary components (equalizer, modulator and PRG) for a fully-functional
/// PUSCH demodulator.
static std::unique_ptr<srsran::pusch_demodulator> create_pusch_demodulator();

/// Implements a PUSCH demodulator following the srsran_mex_dispatcher template.
class MexFunction : public srsran_mex_dispatcher
{
public:
  /// \brief Constructor.
  ///
  /// Stores the string identifier&ndash;method pairs that form the public interface of the PUSCH demodulator MEX
  /// object.
  MexFunction()
  {
    // Ensure srsRAN PUSCH demodulator was created successfully.
    if (!demodulator) {
      mex_abort("Cannot create srsRAN PUSCH demodulator.");
    }

    create_callback("step", [this](ArgumentList out, ArgumentList in) { return this->method_step(out, in); });
  }

private:
  /// Checks that outputs/inputs arguments match the requirements of method_step().
  void check_step_outputs_inputs(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs);

  /// \brief Demodulates a PUSCH transmission according to the given configuration.
  ///
  /// The method takes five inputs.
  ///   - The string <tt>"step"</tt>.
  ///   - A three-dimensional array of \c cf_t containing the receiver-side resource grid.
  ///   - A three-dimensional array of \c cf_t containing the estimated channel coefficients for all REs of all Rx ports
  ///     (currently, only one transmission layer is supported).
  ///   - A \c float providing the noise variance.
  ///   - A one-dimesional structure that describes the PUSCH demodulator configuration. The fields are
  ///      - \c RNTI, radio network temporary identifier;
  ///      - \c RBMask, allocation RB list (as a boolean mask);
  ///      - \c Modulation, modulation scheme used for transmission;
  ///      - \c StartSymbolIndex, start symbol index of the time domain allocation within a slot;
  ///      - \c NumSymbols, number of symbols of the time domain allocation within a slot;
  ///      - \c DMRSSymbPos, boolean mask flagging the OFDM symbols containing DMRS;
  ///      - \c DMRSConfigType, DMRS configuration type;
  ///      - \c NumCdmGroupsWithoutData, number of DMRS CDM groups without data;
  ///      - \c NID, scrambling identifier;
  ///      - \c NumLayers, number of transmit layers;
  ///      - \c Placeholders, ULSCH Scrambling placeholder list;
  ///      - \c RxPorts, receive antenna port indices the PUSCH transmission is mapped to;
  ///
  /// The method has one single output.
  ///   - An array of \c log_likelihood_ratio resulting from the PUSCH demodulation.
  void method_step(ArgumentList outputs, ArgumentList inputs);

  /// A pointer to the actual PUSCH decoder.
  std::unique_ptr<srsran::pusch_demodulator> demodulator = create_pusch_demodulator();

  /// Temporal list of PUSCH RE coordinates.
  srsran::static_vector<srsran::resource_grid_coordinate,
                        srsran::MAX_NOF_PRBS * srsran::NRE * srsran::NOF_OFDM_SYM_PER_SLOT_NORMAL_CP>
      pusch_coordinates_list;
};

std::unique_ptr<srsran::pusch_demodulator> create_pusch_demodulator()
{
  using namespace srsran;

  std::shared_ptr<channel_equalizer_factory> equalizer_factory = create_channel_equalizer_factory_zf();

  std::shared_ptr<channel_modulation_factory> demod_factory = create_channel_modulation_sw_factory();

  std::shared_ptr<pseudo_random_generator_factory> prg_factory = create_pseudo_random_generator_sw_factory();

  std::shared_ptr<pusch_demodulator_factory> pusch_demod_factory =
      create_pusch_demodulator_factory_sw(equalizer_factory, demod_factory, prg_factory);

  return pusch_demod_factory->create();
}
