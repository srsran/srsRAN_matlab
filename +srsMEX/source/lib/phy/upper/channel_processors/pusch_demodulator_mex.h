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
/// \brief PUSCH demodulator MEX declaration.

#pragma once

#include "srsran_matlab/srsran_mex_dispatcher.h"
#include "srsran/phy/upper/channel_processors/pusch/factories.h"
#include "srsran/phy/upper/channel_processors/pusch/pusch_demodulator.h"
#include "srsran/phy/upper/equalization/channel_equalizer_algorithm_type.h"
#include "srsran/phy/upper/equalization/equalization_factories.h"

/// \brief Factory method for a PUSCH demodulator.
///
/// Creates and assemblies all the necessary components (equalizer, modulator and PRG) for a fully-functional
/// PUSCH demodulator.
inline std::unique_ptr<srsran::pusch_demodulator> create_pusch_demodulator();

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
    create_callback("new", [this](ArgumentList out, ArgumentList in) { return this->method_new(out, in); });
    create_callback("step", [this](ArgumentList out, ArgumentList in) { return this->method_step(out, in); });
  }

private:
  /// Checks that outputs/inputs arguments match the requirements of method_step().
  void check_step_outputs_inputs(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs);

  /// \brief Creates a new PUSCH demodulator MEX object.
  ///
  /// This method creates the srsRAN PUSCH demodulator object used by MEX wrapper, with the given equalization strategy.
  ///
  /// The methods accepts only two inputs.
  ///   - The string <tt>"new"</tt>.
  ///   - A string identifying the equalizer strategy (one of <tt>"ZF"</tt> for zero-forcing or <tt>"MMSE"</tt> for
  ///     linear minimum mean-squared error).
  ///
  /// The method has no output.
  void method_new(ArgumentList outputs, ArgumentList inputs);

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
  std::unique_ptr<srsran::pusch_demodulator> demodulator = nullptr;
};

inline std::unique_ptr<srsran::pusch_demodulator>
create_pusch_demodulator(srsran::channel_equalizer_algorithm_type eq_type)
{
  using namespace srsran;

  std::shared_ptr<dft_processor_factory> dft_proc_factory = create_dft_processor_factory_fftw_slow();

  std::shared_ptr<transform_precoder_factory> transform_precod_factory =
      create_dft_transform_precoder_factory(dft_proc_factory, MAX_RB);

  std::shared_ptr<channel_equalizer_factory> equalizer_factory = create_channel_equalizer_generic_factory(eq_type);

  std::shared_ptr<demodulation_mapper_factory> demod_factory = create_demodulation_mapper_factory();

  std::shared_ptr<pseudo_random_generator_factory> prg_factory = create_pseudo_random_generator_sw_factory();

  std::shared_ptr<pusch_demodulator_factory> pusch_demod_factory = create_pusch_demodulator_factory_sw(
      equalizer_factory, transform_precod_factory, demod_factory, nullptr, prg_factory, MAX_RB);

  return pusch_demod_factory->create();
}
