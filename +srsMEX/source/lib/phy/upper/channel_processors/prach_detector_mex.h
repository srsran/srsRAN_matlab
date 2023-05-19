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
/// \brief PRACH detector MEX declaration.

#pragma once

#include "srsran_matlab/srsran_mex_dispatcher.h"
#include "srsran/phy/generic_functions/generic_functions_factories.h"
#include "srsran/phy/support/support_factories.h"
#include "srsran/phy/upper/channel_processors/channel_processor_factories.h"
#include "srsran/phy/upper/channel_processors/prach_detector.h"

/// \brief Factory method for a PRACH detector.
///
/// Creates and assemblies all the necessary components (DFT, PRACH generator, ...) for a fully-functional
/// PRACH detector.
static std::unique_ptr<srsran::prach_detector> create_prach_detector();

/// Fixed DFT size of the PRACH detecter.
static constexpr unsigned DFT_SIZE_DETECTOR = 1536;

/// Implements a PRACH detector following the srsran_mex_dispatcher template.
class MexFunction : public srsran_mex_dispatcher
{
public:
  /// \brief Constructor.
  ///
  /// Stores the string identifier&ndash;method pairs that form the public interface of the PRACH decoder MEX object.
  MexFunction()
  {
    // Ensure srsran PRACH decoder was created successfully.
    if (!detector) {
      mex_abort("Cannot create srsran PRACH detector.");
    }

    create_callback("set_delay",
                    [this](ArgumentList& out, ArgumentList& in) { return this->method_set_delay(out, in); });
    create_callback("step", [this](ArgumentList& out, ArgumentList& in) { return this->method_step(out, in); });
  }

private:
  /// Delay in samples to be tested.
  int delay_samples;

  /// Checks that outputs/inputs arguments match the requirements of method_step().
  void check_step_outputs_inputs(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs);

  /// \brief Sets the delay parameter of the PRACH decoder MEX object under test.
  ///
  /// The method takes two inputs.
  ///   - The string <tt>"set_delay"</tt>.
  ///   - An \c int32_t array providing the sample delay value to be tested.
  ///
  /// The method has no outputs.
  void method_set_delay(ArgumentList& outputs, ArgumentList& inputs);

  /// \brief Detects PRACH transmissions according to the given configuration.
  ///
  /// The method takes three inputs.
  ///   - The string <tt>"step"</tt>.
  ///   - An array of \c cf_t containing the baseband input signal.
  ///   - A one-dimesional structure that describes the PRACH configuration. The fields are
  ///      - \c root_sequence_index, the root sequence index;
  ///      - \c format, preamble format;
  ///      - \c restricted_set, restricted set configuration;
  ///      - \c zero_correlation_zone, zero-correlation zone configuration index;
  ///      - \c start_preamble_index, start preamble index to monitor;
  ///      - \c nof_preamble_indices, number of preamble indices to monitor;
  ///
  /// The method has one single output.
  ///   - A two-dimensional structure with the detected preambles. Each field comprises a structure using the
  ///     fields:
  ///      - \c nof_detected_preambles, number of detected PRACH preambles (should be one);
  ///      - \c preamble_index, index of the detected preamble;
  ///      - \c time_advance, timing advance between the observed arrival time and the reference uplink time;
  ///      - \c power_dB, average RSRP value in dB;
  ///      - \c snr_dB, average SNR value in dB;
  ///      - \c rssi_dB, average RSSI value in dB;
  ///      - \c time_resolution, time resoultion of the PRACH detector;
  ///      - \c time_advance_max, maximum time in advance of the PRACH detector;
  void method_step(ArgumentList& outputs, ArgumentList& inputs);

  /// A pointer to the actual PUSCH decoder.
  std::unique_ptr<srsran::prach_detector> detector = create_prach_detector();
};

std::unique_ptr<srsran::prach_detector> create_prach_detector()
{
  using namespace srsran;

  std::shared_ptr<dft_processor_factory> dft_factory = create_dft_processor_factory_generic();

  std::shared_ptr<prach_generator_factory> generator_factory = create_prach_generator_factory_sw();

  std::shared_ptr<prach_detector_factory> detector_factory =
      create_prach_detector_factory_simple(dft_factory, generator_factory, DFT_SIZE_DETECTOR);

  return detector_factory->create();
}
