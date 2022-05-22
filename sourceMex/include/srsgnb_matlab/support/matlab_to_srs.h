/// \file
/// \brief Helper functions to convert variables from MATLAB convention to SRSGNB convention.

#ifndef SRSGNB_MATLAB_SUPPORT_MATLAB_TO_SRS_H
#define SRSGNB_MATLAB_SUPPORT_MATLAB_TO_SRS_H

#include "srsgnb/phy/modulation_scheme.h"
#include "srsgnb/ran/ldpc_base_graph.h"
#include "srsgnb/support/srsran_assert.h"
#include <string>

namespace srsgnb_matlab {

/// \brief Converts modulation names from MATLAB convention to SRSGNB convention.
/// \param[in] modulation_name   A string identifying a NR modulation according to MATLAB convention.
/// \return A modulation identifier according to SRSGNB convention.
inline srsgnb::modulation_scheme matlab_to_srs_modulation(const std::string& modulation_name)
{
  if ((modulation_name == "BPSK") || (modulation_name == "pi/2-BPSK")) {
    return srsgnb::modulation_scheme::BPSK;
  }
  if (modulation_name == "QPSK") {
    return srsgnb::modulation_scheme::QPSK;
  }
  if ((modulation_name == "QAM16") || (modulation_name == "16QAM")) {
    return srsgnb::modulation_scheme::QAM16;
  }
  if ((modulation_name == "QAM64") || (modulation_name == "64QAM")) {
    return srsgnb::modulation_scheme::QAM64;
  }
  if ((modulation_name == "QAM256") || (modulation_name == "256QAM")) {
    return srsgnb::modulation_scheme::QAM256;
  }
  srsgnb::srsran_terminate("Unknown modulation {}.", modulation_name);
}

/// \brief Converts a MATLAB base graph index to an SRSGNB base graph identifier.
/// \param[in] bg  An LDPC base graph index in {1, 2}.
/// \return An LDPC base graph identifier according to SRSGNB convention.
inline srsgnb::ldpc_base_graph_type matlab_to_srs_base_graph(unsigned bg)
{
  if (bg == 1) {
    return srsgnb::ldpc_base_graph_type::BG1;
  }
  if (bg == 2) {
    return srsgnb::ldpc_base_graph_type::BG2;
  }
  srsgnb::srsran_terminate("Unknown base graph {}.", bg);
}

} // namespace srsgnb_matlab

#endif // SRSGNB_MATLAB_SUPPORT_MATLAB_TO_SRS_H
