#include "prach_detector_mex.h"
#include "srsran_matlab/support/matlab_to_srs.h"
#include "srsran/srsvec/copy.h"

using matlab::mex::ArgumentList;
using namespace matlab::data;
using namespace srsran;
using namespace srsran_matlab;

void MexFunction::check_step_outputs_inputs(ArgumentList outputs, ArgumentList inputs)
{
  if (inputs.size() != 3) {
    mex_abort("Wrong number of inputs.");
  }

  if (inputs[1].getType() != ArrayType::COMPLEX_DOUBLE) {
    mex_abort("Input 'prach_symbols' must be an array of double.");
  }

  if ((inputs[2].getType() != ArrayType::STRUCT) || (inputs[2].getNumberOfElements() > 1)) {
    mex_abort("Input 'config' must be a scalar structure.");
  }

  if (outputs.size() != 1) {
    mex_abort("Wrong number of outputs.");
  }
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
void MexFunction::method_set_delay(ArgumentList& outputs, ArgumentList& inputs)
{
  if (outputs.size() > 0) {
    mex_abort("No output is expected.");
  }

  if ((inputs[1].getType() != ArrayType::DOUBLE) || (inputs[1].getNumberOfElements() > 1)) {
    mex_abort("Second input must be a scalar double.");
  }

  delay_samples = (int)inputs[1][0];
}

void MexFunction::method_step(ArgumentList& outputs, ArgumentList& inputs)
{
  check_step_outputs_inputs(outputs, inputs);

  StructArray in_struct_array = inputs[2];
  Struct      in_det_cfg      = in_struct_array[0];

  prach_detector::configuration detector_config;

  // Restricted sets are not implemented. Skip.
  CharArray restricted_set_in    = in_det_cfg["restricted_set"];
  detector_config.restricted_set = matlab_to_srs_restricted_set(restricted_set_in.toAscii());
  if (detector_config.restricted_set == restricted_set_config::UNRESTRICTED) {
    detector_config.root_sequence_index   = in_det_cfg["root_sequence_index"][0];
    CharArray format_in                   = in_det_cfg["format"];
    detector_config.format                = matlab_to_srs_preamble_format(format_in.toAscii());
    detector_config.zero_correlation_zone = in_det_cfg["zero_correlation_zone"][0];
    detector_config.start_preamble_index  = 0;
    detector_config.nof_preamble_indices  = 64;

    // Create buffer.
    std::unique_ptr<prach_buffer> buffer = create_prach_buffer_long(1);
    if (!buffer) {
      mex_abort("Cannot create srsran PRACH buffer long.");
    }

    // Get frequency domain data.
    const TypedArray<std::complex<double>> in_cft_array = inputs[1];
    std::vector<cf_t>                      frequency_data(in_cft_array.cbegin(), in_cft_array.cend());
    std::transform(
        frequency_data.begin(), frequency_data.end(), frequency_data.begin(), [&, n = 0](cf_t sample) mutable {
          return sample * std::exp(-COMPLEX_J * TWOPI * static_cast<float>(n++) * static_cast<float>(delay_samples) /
                                   static_cast<float>(DFT_SIZE_DETECTOR));
        });

    // Fill buffer with time frequency-domain data.
    srsvec::copy(buffer->get_symbol(0, 0, 0, 0), span<cf_t>(frequency_data).first(839));

    // Run generator.
    prach_detection_result result = detector->detect(*buffer, detector_config);

    // Number of detected PRACH preambles.
    unsigned nof_detected_preambles = result.preambles.size();
    if (nof_detected_preambles == 0) {
      mex_abort("No PRACH preambles were detected.");
    } else {
      // Detected PRACH preamble parameters.
      prach_detection_result::preamble_indication& preamble_indication          = result.preambles.back();
      StructArray                                  detected_preamble_indication = factory.createStructArray({1, 1},
                                                                           {"nof_detected_preambles",
                                                                                                             "preamble_index",
                                                                                                             "time_advance",
                                                                                                             "power_dB",
                                                                                                             "snr_dB",
                                                                                                             "rssi_dB",
                                                                                                             "time_resolution",
                                                                                                             "time_advance_max"});
      detected_preamble_indication[0]["nof_detected_preambles"] = factory.createScalar(result.preambles.size());
      detected_preamble_indication[0]["preamble_index"] = factory.createScalar(preamble_indication.preamble_index);
      detected_preamble_indication[0]["time_advance"] =
          factory.createScalar(preamble_indication.time_advance.to_seconds());
      detected_preamble_indication[0]["power_dB"]         = factory.createScalar(preamble_indication.power_dB);
      detected_preamble_indication[0]["snr_dB"]           = factory.createScalar(preamble_indication.snr_dB);
      detected_preamble_indication[0]["rssi_dB"]          = factory.createScalar(result.rssi_dB);
      detected_preamble_indication[0]["time_resolution"]  = factory.createScalar(result.time_resolution.to_seconds());
      detected_preamble_indication[0]["time_advance_max"] = factory.createScalar(result.time_advance_max.to_seconds());
      outputs[0]                                          = detected_preamble_indication;
    }
  } else {
    std::cout << "Skipping test case with 'RESTRICTED' set configuration.\n";
  }
}
