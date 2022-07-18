#include "pusch_decoder_mex.h"
#include "srsgnb/phy/modulation_scheme.h"
#include "srsgnb/phy/upper/channel_coding/ldpc/ldpc.h"
#include "srsgnb/phy/upper/rx_softbuffer_pool.h"
#include "srsgnb/srslog/bundled/fmt/format.h"
#include "srsgnb_matlab/support/matlab_to_srs.h"

#include <memory>

using matlab::mex::ArgumentList;
using namespace matlab::data;
using namespace srsgnb;
using namespace srsgnb_matlab;

namespace srsgnb {
/// Describes a softbuffer pool.
struct rx_softbuffer_pool_description {
  /// Maximum size of the codeblocks stored in the pool.
  unsigned max_codeblock_size;
  /// Maximum number of softbuffers managed by the pool.
  unsigned max_softbuffers;
  /// Maximum number of codeblocks in each softbuffer.
  unsigned max_nof_codeblocks;
  /// Softbuffer expiration time in number of slots.
  unsigned expire_timeout_slots;
};

std::unique_ptr<rx_softbuffer_pool> create_rx_softbuffer_pool(const rx_softbuffer_pool_description& config);

} // namespace srsgnb

rx_softbuffer* MexFunction::pusch_memento::retrieve_softbuffer(const rx_softbuffer_identifier& id,
                                                               const unsigned                  nof_codeblocks)
{
  return pool->reserve_softbuffer({}, id, nof_codeblocks);
}

rx_softbuffer*
MexFunction::retrieve_softbuffer(uint64_t key, const rx_softbuffer_identifier& id, const unsigned nof_codeblocks)
{
  std::shared_ptr<memento> mem = storage.get_memento(key);
  if (!mem) {
    mex_abort(fmt::format("Cannot retrieve rx_softbuffer_pool with key {}.", key));
  }

  auto           pusch_mem  = std::dynamic_pointer_cast<pusch_memento>(storage.get_memento(key));
  rx_softbuffer* softbuffer = pusch_mem->retrieve_softbuffer(id, nof_codeblocks);
  if (softbuffer == nullptr) {
    std::string msg =
        fmt::format("Cannot retrieve softbuffer with key {}, buffer ID ({}, {}) and nr. of codeblocks {}.",
                    key,
                    id.rnti,
                    id.harq_ack_id,
                    nof_codeblocks);
    mex_abort(msg);
  }
  return softbuffer;
}

void MexFunction::check_step_outputs_inputs(ArgumentList outputs, ArgumentList inputs)
{
  if (inputs.size() != 6) {
    mex_abort("Wrong number of inputs.");
  }

  if ((inputs[1].getType() != ArrayType::UINT64) || (inputs[1].getNumberOfElements() > 1)) {
    mex_abort("Input 'softbufferPoolID' should be a scalar uint64_t");
  }

  if (inputs[2].getType() != ArrayType::INT8) {
    mex_abort("Input 'llrs' must be an array of int8_t.");
  }

  if ((inputs[3].getType() != ArrayType::LOGICAL) || (inputs[3].getNumberOfElements() > 1)) {
    mex_abort("Input 'new_data' must be a scalar logical.");
  }

  if ((inputs[4].getType() != ArrayType::STRUCT) || (inputs[4].getNumberOfElements() > 1)) {
    mex_abort("Input 'seg_cfg' must be a scalar structure.");
  }

  if ((inputs[5].getType() != ArrayType::STRUCT) || (inputs[4].getNumberOfElements() > 1)) {
    mex_abort("Input 'buf_id' must be a scalar structure.");
  }

  if (outputs.size() != 2) {
    mex_abort("Wrong number of outputs.");
  }
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
void MexFunction::method_new(ArgumentList& outputs, ArgumentList& inputs)
{
  if (outputs.size() != 1) {
    mex_abort("Only one output expected.");
  }

  if ((inputs[1].getType() != ArrayType::STRUCT) || (inputs[1].getNumberOfElements() != 1)) {
    mex_abort("Second input must be a scalar structure.");
  }
  rx_softbuffer_pool_description pool_config = {};

  StructArray in_struct            = inputs[1];
  Struct      softbuffer_conf      = in_struct[0];
  pool_config.max_codeblock_size   = softbuffer_conf["max_codeblock_size"][0];
  pool_config.max_softbuffers      = softbuffer_conf["max_softbuffers"][0];
  pool_config.max_nof_codeblocks   = softbuffer_conf["max_nof_codeblocks"][0];
  pool_config.expire_timeout_slots = softbuffer_conf["expire_timeout_slots"][0];

  std::shared_ptr<memento> mem = std::make_shared<pusch_memento>(create_rx_softbuffer_pool(pool_config));
  if (!mem) {
    mex_abort("Cannot create PUSCH memento.");
  }
  uint64_t             key      = storage.store(mem);
  TypedArray<uint64_t> pool_key = factory.createScalar(key);
  outputs[0]                    = pool_key;
}

void MexFunction::method_step(ArgumentList& outputs, ArgumentList& inputs)
{
  check_step_outputs_inputs(outputs, inputs);

  const TypedArray<int8_t>                in_int8_array = inputs[2];
  const std::vector<log_likelihood_ratio> llrs(in_int8_array.cbegin(), in_int8_array.cend());

  bool new_data = static_cast<TypedArray<bool> >(inputs[3])[0];

  StructArray      in_struct_array = inputs[4];
  Struct           in_seg_cfg      = in_struct_array[0];
  segmenter_config seg_cfg         = {};
  seg_cfg.base_graph               = matlab_to_srs_base_graph(in_seg_cfg["base_graph"][0]);
  CharArray in_mod_scheme          = in_seg_cfg["modulation"];
  seg_cfg.mod                      = matlab_to_srs_modulation(in_mod_scheme.toAscii());
  seg_cfg.nof_ch_symbols           = in_seg_cfg["nof_ch_symbols"][0];
  seg_cfg.nof_layers               = in_seg_cfg["nof_layers"][0];
  seg_cfg.rv                       = in_seg_cfg["rv"][0];
  seg_cfg.Nref                     = in_seg_cfg["Nref"][0];

  unsigned tbs       = in_seg_cfg["tbs"][0];
  unsigned tbs_bytes = tbs / 8;

  in_struct_array                    = inputs[5];
  Struct                   in_buf_id = in_struct_array[0];
  rx_softbuffer_identifier buf_id    = {};
  buf_id.harq_ack_id                 = in_buf_id["harq_ack_id"][0];
  buf_id.rnti                        = in_buf_id["rnti"][0];

  unsigned nof_codeblocks       = in_buf_id["nof_codeblocks"][0];
  unsigned nof_codeblocks_check = ldpc::compute_nof_codeblocks(tbs, seg_cfg.base_graph);
  if (nof_codeblocks != nof_codeblocks_check) {
    std::string msg =
        fmt::format("Softbuffer ({}, {}) requested with {} codeblocks, but the codeword has {} codeblocks.",
                    buf_id.rnti,
                    buf_id.harq_ack_id,
                    nof_codeblocks,
                    nof_codeblocks_check);
    mex_abort(msg);
  }

  uint64_t key = static_cast<TypedArray<uint64_t> >(inputs[1])[0];

  rx_softbuffer*               softbuffer = retrieve_softbuffer(key, buf_id, nof_codeblocks);
  pusch_decoder::statistics    dec_stats  = {};
  pusch_decoder::configuration cfg        = {seg_cfg, 6, true, new_data};
  std::vector<uint8_t>         rx_tb(tbs_bytes);
  decoder->decode(rx_tb, dec_stats, softbuffer, llrs, cfg);

  TypedArray<uint8_t> out = factory.createArray({rx_tb.size(), 1}, rx_tb.cbegin(), rx_tb.cend());
  outputs[0]              = out;

  StructArray S      = factory.createStructArray({1, 1}, {"crc_ok", "ldpc_iters"});
  S[0]["crc_ok"]     = factory.createScalar(dec_stats.tb_crc_ok);
  S[0]["ldpc_iters"] = factory.createScalar(dec_stats.ldpc_decoder_stats.get_max());
  outputs[1]         = S;
}

void MexFunction::method_reset_crcs(ArgumentList& outputs, ArgumentList& inputs)
{
  if (outputs.size() != 0) {
    mex_abort("No outputs expected.");
  }

  if (inputs.size() != 3) {
    mex_abort("Wrong number of inputs.");
  }

  if ((inputs[1].getType() != ArrayType::UINT64) || (inputs[1].getNumberOfElements() > 1)) {
    mex_abort("Input softbufferPoolID should be a scalar uint64_t");
  }

  if ((inputs[2].getType() != ArrayType::STRUCT) || (inputs[2].getNumberOfElements() > 1)) {
    mex_abort("Input 'buf_id' must be a scalar structure.");
  }

  StructArray              in_struct_array = inputs[2];
  Struct                   in_buf_id       = in_struct_array[0];
  rx_softbuffer_identifier buf_id          = {};
  buf_id.harq_ack_id                       = in_buf_id["harq_ack_id"][0];
  buf_id.rnti                              = in_buf_id["rnti"][0];

  unsigned nof_codeblocks = in_buf_id["nof_codeblocks"][0];

  uint64_t key = static_cast<TypedArray<uint64_t> >(inputs[1])[0];

  rx_softbuffer* softbuffer = retrieve_softbuffer(key, buf_id, nof_codeblocks);
  softbuffer->reset_codeblocks_crc();
}

void MexFunction::method_release(ArgumentList& outputs, ArgumentList& inputs)
{
  if (outputs.size() != 0) {
    mex_abort("No outputs expected.");
  }

  if (inputs.size() != 2) {
    mex_abort("Wrong number of inputs.");
  }

  if ((inputs[1].getType() != ArrayType::UINT64) || (inputs[1].getNumberOfElements() > 1)) {
    mex_abort("Input softbufferPoolID should be a scalar uint64_t");
  }

  uint64_t key = static_cast<TypedArray<uint64_t> >(inputs[1])[0];

  if (storage.release_memento(key) == 0) {
    std::string msg = fmt::format("Something wrong, there was no softbuffer pool with softbufferPoolID {}.", key);
    mex_abort(msg);
  }
}