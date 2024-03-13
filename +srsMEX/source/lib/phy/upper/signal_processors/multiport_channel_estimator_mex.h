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
/// \brief Multiport channel estimator MEX declaration.

#pragma once

#include "srsran_matlab/srsran_mex_dispatcher.h"
#include "srsran/phy/generic_functions/generic_functions_factories.h"
#include "srsran/phy/upper/signal_processors/port_channel_estimator.h"
#include "srsran/phy/upper/signal_processors/signal_processor_factories.h"
#include <memory>

/// Factory method for a single port channel estimator.
inline std::unique_ptr<srsran::port_channel_estimator> create_port_channel_estimator();

/// Implements a SIMO channel estimator leveraging srsRAN \c port_channel_estimator.
class MexFunction : public srsran_mex_dispatcher
{
public:
  /// Constructor: creates the \c port_channel_estimator object and the callback step method.
  MexFunction()
  {
    // Ensure the estimator was created successfully.
    if (!estimator) {
      mex_abort("Cannot create srsRAN port channel estimator.");
    }

    create_callback("step", [this](ArgumentList out, ArgumentList in) { return this->method_step(out, in); });
  }

private:
  /// Checks that outputs/inputs arguments match the requirements of method_step().
  void check_step_outputs_inputs(ArgumentList outputs, ArgumentList inputs);

  /// \brief Estimates a SIMO channel.
  ///
  /// The method has 5 inputs.
  ///   - The string <tt>"step"</tt>.
  ///   - A resource grid: a 2- or 3-dimensional array of complex single-precision floats representing the received IQ
  ///     samples for all subcarriers, OFDM symbols and Rx antenna ports.
  ///   - The symbol allocation: a two-element row array with, in order, the 0-based index of the first allocated OFDM
  ///     symbol and the number of (contiguous) allocated OFDM symbols.
  ///   - The list of reference symbols: a column array of complex single-precision floats with the reference symbols
  ///     from all OFDM symbols stacked one after the other.
  ///   - A one-dimensional structure with fields
  ///      - \c CyclicPrefix, the cyclic prefix (either "normal" or "extended");
  ///      - \c SubcarrierSpacing, the subcarrier spacing in kHz (either 15 or 30);
  ///      - \c Symbols, a boolean mask specifying the OFDM symbols carrying DM-RS;
  ///      - \c RBMask, a boolean mask specifying the allocated PRBs (in the first hop);
  ///      - \c HoppingIndex, the index of the first OFDM symbol after intraslot frequency hopping (leave emtpy for no
  ///        frequency hopping.
  ///      - \c RBMask2, a boolean mask specifying the allocated PRBs in the second hop (if pertinent);
  ///      - \c REPattern, a boolean mask specifying the position of the reference symbols within an RB;
  ///      - \c BetaScaling, the DM-RS to data amplitude scaling factor (scalar double);
  ///      - \c PortIndices, a one-dimensional array with the indices of the Rx ports the resource grid refers to.
  ///
  /// The method has 2 outputs.
  ///   - A three-dimensional array of complex single-precision floats with the estimated channel coefficients. This
  ///     array has the same dimensions has the input resource grid, with all the non-allocated coefficients set to
  ///     one.
  ///   - An array of N+1 structures with extra estimated metrics. Here, N stands for the number of Rx ports. The
  ///     fields are
  ///      - \c NoiseVar, the estimated noise variance;
  ///      - \c RSRP, the estimated RSRP;
  ///      - \c EPRE, the estimated EPRE;
  ///      - \c SINR, the estimated SINR;
  ///      - \c TimeAlignment, the estimated time alignment of the UE.
  ///     The first N entries refer to each one of the Rx ports, in order, while the last entry provide combined
  ///     metrics (except for the combined SINR, which cannot be computed here, and is set to NaN).
  void method_step(ArgumentList outputs, ArgumentList inputs);

  /// Pointer to the actual port channel estimator.
  std::unique_ptr<srsran::port_channel_estimator> estimator = create_port_channel_estimator();
};

std::unique_ptr<srsran::port_channel_estimator> create_port_channel_estimator()
{
  using namespace srsran;
  std::shared_ptr<dft_processor_factory>            dft_factory = create_dft_processor_factory_fftw_slow();
  std::shared_ptr<time_alignment_estimator_factory> ta_est_factory =
      create_time_alignment_estimator_dft_factory(dft_factory);
  std::shared_ptr<port_channel_estimator_factory> estimator_factory =
      create_port_channel_estimator_factory_sw(ta_est_factory);
  return estimator_factory->create();
}
