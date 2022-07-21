/// \file
/// \brief PUSCH decoder MEX declaration.

#pragma once

#include "srsgnb/phy/upper/channel_processors/channel_processor_factories.h"
#include "srsgnb/phy/upper/channel_processors/pusch_decoder.h"
#include "srsgnb/phy/upper/rx_softbuffer.h"
#include "srsgnb/phy/upper/rx_softbuffer_pool.h"
#include "srsgnb_matlab/srsgnb_mex_dispatcher.h"
#include "srsgnb_matlab/support/memento.h"

#include <memory>

/// \brief Factory method for a PUSCH decoder.
///
/// Creates and assemblies all the necessary components (LDPC blocks, CRC calculators, ...) for a fully-functional
/// PUSCH decoder.
static std::unique_ptr<srsgnb::pusch_decoder> create_pusch_decoder();

/// Implements a PUSCH decoder following the srsgnb_mex_dispatcher template.
class MexFunction : public srsgnb_mex_dispatcher
{
  /// State snapshot of a PUSCH decoder MEX object.
  class pusch_memento : public memento
  {
  public:
    /// \brief Creator.
    ///
    /// The memento object consists of the pointer to the \c rx_softbuffer_pool used by the PUSCH decoder to store and
    /// combine LLRs from different retransmissions as well as segment data corresponding to decoded codeblocks that
    /// pass the CRC checksum.
    explicit pusch_memento(std::unique_ptr<srsgnb::rx_softbuffer_pool> p) : pool(std::move(p)){};

    /// \brief Gets a softbuffer from the softbuffer pool stored in the memento.
    ///
    /// This function requests a softbuffer to the softbuffer pool stored in the memento. Depending on whether a
    /// softbuffer with the same ID and number of codeblocks exists or not, the pool will return the existing
    /// softbuffer or create a new one.
    /// \param[in] id              Softbuffer identifier (UE RNTI and HARQ process ID).
    /// \param[in] nof_codeblocks  Number of codeblocks forming the codeword (or, equivalently, the transport block).
    /// \return A pointer to the identified softbuffer.
    srsgnb::rx_softbuffer* retrieve_softbuffer(const srsgnb::rx_softbuffer_identifier& id, unsigned nof_codeblocks);

  private:
    /// Pointer to the softbuffer pool stored in the memento.
    std::unique_ptr<srsgnb::rx_softbuffer_pool> pool;
  };

public:
  /// \brief Constructor.
  ///
  /// Stores the string identifier&ndash;method pairs that form the public interface of the PUSCH decoder MEX object.
  MexFunction()
  {
    // Ensure srsgnb PUSCH decoder was created successfully.
    if (!decoder) {
      mex_abort("Cannot create srsgnb PUSCH decoder.");
    }

    create_callback("new", [this](ArgumentList& out, ArgumentList& in) { return this->method_new(out, in); });
    create_callback("step", [this](ArgumentList& out, ArgumentList& in) { return this->method_step(out, in); });
    create_callback("reset_crcs",
                    [this](ArgumentList& out, ArgumentList& in) { return this->method_reset_crcs(out, in); });
    create_callback("release", [this](ArgumentList& out, ArgumentList& in) { return this->method_release(out, in); });
  }

private:
  /// \brief Retrieves a softbuffer from a memento object.
  ///
  /// See also pusch_memento::retrieve_softbuffer().
  /// \param[in] key             The PUSCH memento identifier.
  /// \param[in] id              The softbuffer identifier (UE RNTI and HARQ process ID).
  /// \param[in] nof_codeblocks  The number of codeblocks in the current codeword.
  /// \return A pointer to the requested softbuffer from the softbuffer pool associated to the given memento identifier.
  srsgnb::rx_softbuffer*
  retrieve_softbuffer(uint64_t key, const srsgnb::rx_softbuffer_identifier& id, unsigned nof_codeblocks);

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
  ///   - A one-dimensional structure with fields (see also srsgnb::rx_softbuffer_pool_description):
  ///      - \c max_codeblock_size, maximum size of the codeblocks stored in the pool;
  ///      - \c max_softbuffers, maximum number of softbuffers managed by the pool;
  ///      - \c max_nof_codeblocks, maximum number of codeblocks managed by the pool (shared by all softbuffers); and
  ///      - \c expire_timeout_slots, softbuffer expiration time as a number of slots.
  ///
  /// The only output of the method is the identifier of the created pool (a \c uint64_t number).
  void method_new(ArgumentList& outputs, ArgumentList& inputs);

  /// \brief Decodes one codeword.
  ///
  /// The method takes six inputs.
  ///   - The string <tt>"step"</tt>.
  ///   - A softbuffer pool identifier (a \c uint64_t number).
  ///   - An array of \c int8 containing the codeword log-likelihood ratios.
  ///   - A scalar logical indicating whether the LLRs correspond to a new transmission (\c true) or to a retransmission
  ///     in a HARQ process (\c false).
  ///   - A one-dimensional structure that describes the segmentation of the transport block. The fields are
  ///      - \c base_graph, the LDPC base graph;
  ///      - \c modulation, modulation identifier;
  ///      - \c nof_ch_symbols, the number of channel symbols corresponding to one codeword;
  ///      - \c nof_layers, the number of transmission layers;
  ///      - \c rv, the redundancy version;
  ///      - \c Nref, limited buffer rate matching length (set to zero for unlimited buffer);
  ///      - \c tbs, the transport block size.
  ///   - A one-dimensional structure with fields
  ///      - \c harq_ack_id, the ID of the HARQ process;
  ///      - \c rnti, the UE RNTI;
  ///      - \c nof_codeblocks, the number of codeblocks forming the codeword.
  ///
  /// The method has two outputs.
  ///   - The decoded transport block (in packed format).
  ///   - A one-dimensional structure with decoding statistics. The fields are
  ///      - \c crc_ok, equal to \c true if the codeword CRC is valid, \c false if invalid;
  ///      - \c ldpc_iters, the maximum number of LDPC iterations across all codeblocks forming the codeword.
  void method_step(ArgumentList& outputs, ArgumentList& inputs);

  /// \brief Resets the CRC status of a softbuffer.
  ///
  /// The method takes three inputs.
  ///   - The string <tt>"reset_crcs"</tt>.
  ///   - A softbuffer pool identifier (a \c uint64_t number).
  ///   - A one-dimensional structure with fields
  ///      - \c harq_ack_id, the ID of the HARQ process;
  ///      - \c rnti, the UE RNTI;
  ///      - \c nof_codeblocks, the number of codeblocks forming the codeword.
  ///
  /// The method has no outputs.
  void method_reset_crcs(ArgumentList& outputs, ArgumentList& inputs);

  /// \brief Releases a softbuffer pool.
  ///
  /// The method takes, as input, a softbuffer pool identifier (a \c uint64_t number). It returns 1 if the
  /// associated softbuffer pool was released, 0 otherwise.
  void method_release(ArgumentList& outputs, ArgumentList& inputs);

  /// A pointer to the actual PUSCH decoder.
  std::unique_ptr<srsgnb::pusch_decoder> decoder = create_pusch_decoder();

  /// A container for pusch_memento objects.
  memento_storage storage = {};
};

std::unique_ptr<srsgnb::pusch_decoder> create_pusch_decoder()
{
  using namespace srsgnb;

  std::shared_ptr<crc_calculator_factory> crc_calculator_factory = create_crc_calculator_factory_sw();

  std::shared_ptr<ldpc_decoder_factory> ldpc_decoder_factory = create_ldpc_decoder_factory_sw("generic");

  std::shared_ptr<ldpc_rate_dematcher_factory> ldpc_rate_dematcher_factory = create_ldpc_rate_dematcher_factory_sw();

  std::shared_ptr<ldpc_segmenter_rx_factory> segmenter_rx_factory = create_ldpc_segmenter_rx_factory_sw();

  pusch_decoder_factory_sw_configuration pusch_decoder_factory_sw_config;
  pusch_decoder_factory_sw_config.crc_factory       = crc_calculator_factory;
  pusch_decoder_factory_sw_config.decoder_factory   = ldpc_decoder_factory;
  pusch_decoder_factory_sw_config.dematcher_factory = ldpc_rate_dematcher_factory;
  pusch_decoder_factory_sw_config.segmenter_factory = segmenter_rx_factory;
  std::shared_ptr<pusch_decoder_factory> pusch_decoder_factory =
      create_pusch_decoder_factory_sw(pusch_decoder_factory_sw_config);

  return pusch_decoder_factory->create();
}

