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
/// \brief PUSCH decoder MEX declaration.

#pragma once

#include "srsran_matlab/srsran_mex_dispatcher.h"
#include "srsran_matlab/support/memento.h"
#include "srsran/phy/upper/channel_processors/pusch/factories.h"
#include "srsran/phy/upper/channel_processors/pusch/pusch_decoder.h"
#include "srsran/phy/upper/rx_buffer.h"
#include "srsran/phy/upper/rx_buffer_pool.h"
#include "srsran/phy/upper/unique_rx_buffer.h"
#include <memory>

/// \brief Factory method for a PUSCH decoder.
///
/// Creates and assemblies all the necessary components (LDPC blocks, CRC calculators, ...) for a fully-functional
/// PUSCH decoder.
inline std::unique_ptr<srsran::pusch_decoder> create_pusch_decoder();

/// Implements a PUSCH decoder following the srsran_mex_dispatcher template.
class MexFunction : public srsran_mex_dispatcher
{
  /// State snapshot of a PUSCH decoder MEX object.
  class pusch_memento
  {
  public:
    /// \brief Creator.
    ///
    /// The memento object consists of the pointer to the \c rx_buffer_pool used by the PUSCH decoder to store and
    /// combine LLRs from different retransmissions as well as segment data corresponding to decoded codeblocks that
    /// pass the CRC checksum.
    explicit pusch_memento(std::unique_ptr<srsran::rx_buffer_pool_controller> p) : pool(std::move(p)) {}

    /// \brief Gets a softbuffer from the softbuffer pool stored in the memento.
    ///
    /// This function requests a softbuffer to the softbuffer pool stored in the memento. Depending on whether a
    /// softbuffer with the same ID and number of codeblocks exists or not, the pool will return the existing
    /// softbuffer or create a new one.
    /// \param[in] id              Softbuffer identifier (UE RNTI and HARQ process ID).
    /// \param[in] nof_codeblocks  Number of codeblocks forming the codeword (or, equivalently, the transport block).
    /// \param[in] is_new_data     Boolean flag: true if the softbuffer is requested for a new transmission, false if
    ///                            it is for a retransmission.
    /// \return A pointer to the identified softbuffer.
    srsran::unique_rx_buffer
    retrieve_softbuffer(const srsran::trx_buffer_identifier& id, unsigned nof_codeblocks, bool is_new_data);

  private:
    /// Pointer to the softbuffer pool stored in the memento.
    std::unique_ptr<srsran::rx_buffer_pool_controller> pool;
  };

public:
  /// \brief Constructor.
  ///
  /// Stores the string identifier&ndash;method pairs that form the public interface of the PUSCH decoder MEX object.
  MexFunction()
  {
    // Ensure srsRAN PUSCH decoder was created successfully.
    if (!decoder) {
      mex_abort("Cannot create srsRAN PUSCH decoder.");
    }

    create_callback("new", [this](ArgumentList out, ArgumentList in) { this->method_new(out, in); });
    create_callback("step", [this](ArgumentList out, ArgumentList in) { this->method_step(out, in); });
    create_callback("reset_crcs", [this](ArgumentList out, ArgumentList in) { this->method_reset_crcs(out, in); });
    create_callback("release", [this](ArgumentList out, ArgumentList in) { this->method_release(out, in); });
  }

private:
  /// \brief Retrieves a softbuffer from a memento object.
  ///
  /// See also pusch_memento::retrieve_softbuffer().
  /// \param[in] key             The PUSCH memento identifier.
  /// \param[in] id              The softbuffer identifier (UE RNTI and HARQ process ID).
  /// \param[in] nof_codeblocks  The number of codeblocks in the current codeword.
  /// \param[in] is_new_data     Boolean flag: true if the softbuffer is requested for a new transmission, false if
  ///                            it is for a retransmission.
  /// \return A pointer to the requested softbuffer from the softbuffer pool associated to the given memento identifier.
  srsran::unique_rx_buffer
  retrieve_softbuffer(uint64_t key, const srsran::trx_buffer_identifier& id, unsigned nof_codeblocks, bool is_new_data);

  /// Checks that outputs/inputs arguments match the requirements of method_step().
  void check_step_outputs_inputs(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs);

  /// \brief Creates a new PUSCH decoder MEX object.
  ///
  /// Specifically, this method creates a new softbuffer pool that can be used by the PUSCH decoder for storing LLRs
  /// and decoded data (recall that MATLAB can only instantiate a single object for any MEX function). It is up to
  /// the users to manage the pools and use the correct one depending on the PUSCH transmission they are decoding.
  ///
  /// The method accepts only two inputs.
  ///   - The string <tt>"new"</tt>.
  ///   - A one-dimensional structure with fields (see also srsran::rx_softbuffer_pool_description):
  ///      - \c MaxCodeblockSize, maximum size of the codeblocks stored in the pool;
  ///      - \c MaxSoftbuffers, maximum number of softbuffers managed by the pool;
  ///      - \c MaxCodeblocks, maximum number of codeblocks managed by the pool (shared by all softbuffers); and
  ///      - \c ExpireTimeoutSlots, softbuffer expiration time as a number of slots.
  ///
  /// The only output of the method is the identifier of the created pool (a \c uint64_t number).
  void method_new(ArgumentList outputs, ArgumentList inputs);

  /// \brief Decodes one codeword.
  ///
  /// The method takes six inputs.
  ///   - The string <tt>"step"</tt>.
  ///   - A softbuffer pool identifier (a \c uint64_t number).
  ///   - An array of \c int8 containing the codeword log-likelihood ratios.
  ///   - A scalar logical indicating whether the LLRs correspond to a new transmission (\c true) or to a retransmission
  ///     in a HARQ process (\c false).
  ///   - A one-dimensional structure that describes the segmentation of the transport block. The fields are
  ///      - \c BGN, the LDPC base graph;
  ///      - \c MaximumLDPCIterationCount, the maximum number of LDPC decoding iterations;
  ///      - \c Modulation, modulation identifier;
  ///      - \c NumLayers, the number of transmission layers;
  ///      - \c RV, the redundancy version;
  ///      - \c LimitedBufferSize, limited buffer rate matching length (set to zero for unlimited buffer);
  ///      - \c TransportBlockLength, the transport block size.
  ///   - A one-dimensional structure with fields
  ///      - \c HARQProcessID, the ID of the HARQ process;
  ///      - \c RNTI, the UE RNTI;
  ///      - \c NumCodeblocks, the number of codeblocks forming the codeword.
  ///
  /// The method has two outputs.
  ///   - The decoded transport block (in packed format).
  ///   - A one-dimensional structure with decoding statistics. The fields are
  ///      - \c CRCOK, equal to \c true if the codeword CRC is valid, \c false if invalid;
  ///      - \c LDPCIterationsMax, the maximum number of LDPC iterations across all codeblocks forming the codeword.
  ///      - \c LDPCIterationsMean, the average number of LDPC iterations across all codeblocks forming the codeword.
  void method_step(ArgumentList outputs, ArgumentList inputs);

  /// \brief Resets the CRC status of a softbuffer.
  ///
  /// The method takes three inputs.
  ///   - The string <tt>"reset_crcs"</tt>.
  ///   - A softbuffer pool identifier (a \c uint64_t number).
  ///   - A one-dimensional structure with fields
  ///      - \c HARQProcessID, the ID of the HARQ process;
  ///      - \c RNTI, the UE RNTI;
  ///      - \c NumCodeblocks, the number of codeblocks forming the codeword.
  ///
  /// The method has no outputs.
  void method_reset_crcs(ArgumentList outputs, ArgumentList inputs);

  /// \brief Releases a softbuffer pool.
  ///
  /// The method takes, as input, a softbuffer pool identifier (a \c uint64_t number). It returns 1 if the
  /// associated softbuffer pool was released, 0 otherwise.
  void method_release(ArgumentList outputs, ArgumentList inputs);

  /// A pointer to the actual PUSCH decoder.
  std::unique_ptr<srsran::pusch_decoder> decoder = create_pusch_decoder();

  /// A container for pusch_memento objects.
  memento_storage<pusch_memento> storage;
};

std::unique_ptr<srsran::pusch_decoder> create_pusch_decoder()
{
  using namespace srsran;

  std::shared_ptr<crc_calculator_factory> crc_calculator_factory = create_crc_calculator_factory_sw("auto");

  std::shared_ptr<ldpc_decoder_factory> ldpc_decoder_factory = create_ldpc_decoder_factory_sw("auto");

  std::shared_ptr<ldpc_rate_dematcher_factory> ldpc_rate_dematcher_factory =
      create_ldpc_rate_dematcher_factory_sw("auto");

  std::shared_ptr<ldpc_segmenter_rx_factory> segmenter_rx_factory = create_ldpc_segmenter_rx_factory_sw();

  pusch_decoder_factory_sw_configuration pusch_decoder_factory_sw_config;
  pusch_decoder_factory_sw_config.crc_factory       = crc_calculator_factory;
  pusch_decoder_factory_sw_config.decoder_factory   = ldpc_decoder_factory;
  pusch_decoder_factory_sw_config.dematcher_factory = ldpc_rate_dematcher_factory;
  pusch_decoder_factory_sw_config.segmenter_factory = segmenter_rx_factory;
  pusch_decoder_factory_sw_config.nof_prb           = MAX_RB;
  pusch_decoder_factory_sw_config.nof_layers        = pusch_constants::MAX_NOF_LAYERS;
  std::shared_ptr<pusch_decoder_factory> pusch_decoder_factory =
      create_pusch_decoder_factory_sw(pusch_decoder_factory_sw_config);

  return pusch_decoder_factory->create();
}
