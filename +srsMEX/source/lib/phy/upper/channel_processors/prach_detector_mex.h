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
inline std::unique_ptr<srsran::prach_detector> create_prach_detector();

/// \brief Factory method for a PRACH validator.
///
/// Creates and assemblies all the necessary components (DFT, PRACH generator, ...) for a fully-functional
/// PRACH validator.
inline std::unique_ptr<srsran::prach_detector_validator> create_prach_validator();

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

    create_callback("step", [this](ArgumentList out, ArgumentList in) { this->method_step(out, in); });
  }

private:
  /// Checks that outputs/inputs arguments match the requirements of method_step().
  void check_step_outputs_inputs(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs);

  /// \brief Detects PRACH transmissions according to the given configuration.
  ///
  /// The method takes three inputs.
  ///   - The string <tt>"step"</tt>.
  ///   - An array of \c cf_t containing the baseband input signal.
  ///   - A one-dimesional structure that describes the PRACH configuration. The fields are
  ///      - \c SequenceIndex, the root sequence index;
  ///      - \c Format, preamble format;
  ///      - \c RestrictedSet, restricted set configuration;
  ///      - \c ZeroCorrelationZone, zero-correlation zone configuration index;
  ///      - \c SubcarrierSpacing, the subcarrier spacing in kHz;
  ///
  /// The method has one single output.
  ///   - A two-dimensional structure with the detected preambles. Each field comprises a structure using the
  ///     fields:
  ///      - \c NumDetectedPreambles, number of detected PRACH preambles (should be one);
  ///      - \c RSSIDecibel, average RSSI value in dB;
  ///      - \c TimeResolution, time resoultion of the PRACH detector, in seconds;
  ///      - \c MaxTimeAdvance, maximum timing of the PRACH detector, in seconds;
  ///      - \c PreambleIndices, array of indices of the detected preamble;
  ///      - \c TimeAdvance, array of timing advance between the observed arrival time and the reference uplink time,
  ///        in seconds, for the corresponding preamble indices;
  ///      - \c PowerDecibel, array of average RSRP values in dB, for the corresponding preamble indices;
  ///      - \c SINRDecibel, array of average SNR values in dB, for the corresponding preamble indices;
  void method_step(ArgumentList outputs, ArgumentList inputs);

  /// A pointer to the actual PRACH detector.
  std::unique_ptr<srsran::prach_detector> detector = create_prach_detector();
  /// A pointer to the actual PRACH detector validator.
  std::unique_ptr<srsran::prach_detector_validator> validator = create_prach_validator();
};

std::unique_ptr<srsran::prach_detector> create_prach_detector()
{
  using namespace srsran;

  std::shared_ptr<dft_processor_factory> dft_factory = create_dft_processor_factory_generic();

  std::shared_ptr<prach_generator_factory> generator_factory = create_prach_generator_factory_sw();

  std::shared_ptr<prach_detector_factory> detector_factory =
      create_prach_detector_factory_sw(dft_factory, generator_factory);

  return detector_factory->create();
}

std::unique_ptr<srsran::prach_detector_validator> create_prach_validator()
{
  using namespace srsran;

  std::shared_ptr<dft_processor_factory> dft_factory = create_dft_processor_factory_generic();

  std::shared_ptr<prach_generator_factory> generator_factory = create_prach_generator_factory_sw();

  std::shared_ptr<prach_detector_factory> detector_factory =
      create_prach_detector_factory_sw(dft_factory, generator_factory);

  return detector_factory->create_validator();
}
