/// \file
/// \brief Helper functions to convert variables from MATLAB convention to SRSRAN convention.

#pragma once

#include "srsran/ran/ldpc_base_graph.h"
#include "srsran/ran/modulation_scheme.h"
#include "srsran/support/error_handling.h"
#include "srsran/support/srsran_assert.h"
#include <string>

namespace srsran_matlab {

/// \brief Converts modulation names from MATLAB convention to SRSRAN convention.
/// \param[in] modulation_name   A string identifying a NR modulation according to MATLAB convention.
/// \return A modulation identifier according to SRSRAN convention.
inline srsran::modulation_scheme matlab_to_srs_modulation(const std::string& modulation_name)
{
  if ((modulation_name == "BPSK") || (modulation_name == "pi/2-BPSK")) {
    return srsran::modulation_scheme::BPSK;
  }
  if (modulation_name == "QPSK") {
    return srsran::modulation_scheme::QPSK;
  }
  if ((modulation_name == "QAM16") || (modulation_name == "16QAM")) {
    return srsran::modulation_scheme::QAM16;
  }
  if ((modulation_name == "QAM64") || (modulation_name == "64QAM")) {
    return srsran::modulation_scheme::QAM64;
  }
  if ((modulation_name == "QAM256") || (modulation_name == "256QAM")) {
    return srsran::modulation_scheme::QAM256;
  }
  srsran::srsran_terminate("Unknown modulation {}.", modulation_name);
}

/// \brief Converts a MATLAB base graph index to an SRSRAN base graph identifier.
/// \param[in] bg  An LDPC base graph index in {1, 2}.
/// \return An LDPC base graph identifier according to SRSRAN convention.
inline srsran::ldpc_base_graph_type matlab_to_srs_base_graph(unsigned bg)
{
  if (bg == 1) {
    return srsran::ldpc_base_graph_type::BG1;
  }
  if (bg == 2) {
    return srsran::ldpc_base_graph_type::BG2;
  }
  srsran::srsran_terminate("Unknown base graph {}.", bg);
}

} // namespace srsran_matlab
