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

#include "pusch_decoder_mex.h"
#include "srsran_matlab/support/matlab_to_srs.h"
#include "srsran_matlab/support/to_span.h"
#include "srsran/adt/optional.h"
#include "srsran/phy/upper/channel_coding/ldpc/ldpc.h"
#include "srsran/phy/upper/channel_processors/pusch/pusch_decoder_buffer.h"
#include "srsran/phy/upper/channel_processors/pusch/pusch_decoder_notifier.h"
#include "srsran/phy/upper/channel_processors/pusch/pusch_decoder_result.h"
#include "srsran/phy/upper/rx_softbuffer_pool.h"
#include "srsran/ran/modulation_scheme.h"
#include "srsran/support/units.h"
#include "fmt/format.h"

#include <memory>

using matlab::mex::ArgumentList;
using namespace matlab::data;
using namespace srsran;
using namespace srsran_matlab;

namespace {

class pusch_decoder_notifier_spy : private pusch_decoder_notifier
{
public:
  bool has_result() const { return result.has_value(); }

  const pusch_decoder_result& get_result() const { return result.value(); }

  pusch_decoder_notifier& get_notifier() { return *this; }

private:
  void on_sch_data(const pusch_decoder_result& result_) override { result = result_; }

  srsran::optional<pusch_decoder_result> result;
};

} // namespace

unique_rx_softbuffer MexFunction::pusch_memento::retrieve_softbuffer(const rx_softbuffer_identifier& id,
                                                                     const unsigned                  nof_codeblocks)
{
  return pool->reserve_softbuffer({}, id, nof_codeblocks);
}

unique_rx_softbuffer
MexFunction::retrieve_softbuffer(uint64_t key, const rx_softbuffer_identifier& id, const unsigned nof_codeblocks)
{
  std::shared_ptr<memento> mem = storage.get_memento(key);
  if (!mem) {
    mex_abort("Cannot retrieve rx_softbuffer_pool with key {}.", key);
  }

  auto                 pusch_mem  = std::dynamic_pointer_cast<pusch_memento>(storage.get_memento(key));
  unique_rx_softbuffer softbuffer = pusch_mem->retrieve_softbuffer(id, nof_codeblocks);
  if (!softbuffer.is_valid()) {
    mex_abort("Cannot retrieve softbuffer with key {}, buffer ID ({}, {}) and nr. of codeblocks {}.",
              key,
              id.rnti,
              id.harq_ack_id,
              nof_codeblocks);
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
void MexFunction::method_new(ArgumentList outputs, ArgumentList inputs)
{
  if (outputs.size() != 1) {
    mex_abort("Only one output expected.");
  }

  if ((inputs[1].getType() != ArrayType::STRUCT) || (inputs[1].getNumberOfElements() != 1)) {
    mex_abort("Second input must be a scalar structure.");
  }
  rx_softbuffer_pool_config pool_config = {};

  StructArray in_struct            = inputs[1];
  Struct      softbuffer_conf      = in_struct[0];
  pool_config.max_codeblock_size   = softbuffer_conf["MaxCodeblockSize"][0];
  pool_config.max_softbuffers      = softbuffer_conf["MaxSoftbuffers"][0];
  pool_config.max_nof_codeblocks   = softbuffer_conf["MaxCodeblocks"][0];
  pool_config.expire_timeout_slots = softbuffer_conf["ExpireTimeoutSlots"][0];

  std::shared_ptr<memento> mem = std::make_shared<pusch_memento>(create_rx_softbuffer_pool(pool_config));
  if (!mem) {
    mex_abort("Cannot create PUSCH memento.");
  }
  uint64_t             key      = storage.store(mem);
  TypedArray<uint64_t> pool_key = factory.createScalar(key);
  outputs[0]                    = pool_key;
}

void MexFunction::method_step(ArgumentList outputs, ArgumentList inputs)
{
  check_step_outputs_inputs(outputs, inputs);

  const TypedArray<int8_t>         in_int8_array = inputs[2];
  span<const log_likelihood_ratio> llrs          = to_span<int8_t, log_likelihood_ratio>(in_int8_array);

  StructArray                  in_struct_array = inputs[4];
  Struct                       in_seg_cfg      = in_struct_array[0];
  pusch_decoder::configuration cfg             = {};
  cfg.base_graph                               = matlab_to_srs_base_graph(in_seg_cfg["BGN"][0]);
  CharArray in_mod_scheme                      = in_seg_cfg["Modulation"];
  cfg.mod                                      = matlab_to_srs_modulation(in_mod_scheme.toAscii());
  cfg.nof_layers                               = in_seg_cfg["NumLayers"][0];
  cfg.rv                                       = in_seg_cfg["RV"][0];
  cfg.Nref                                     = in_seg_cfg["LimitedBufferSize"][0];
  cfg.new_data                                 = static_cast<TypedArray<bool>>(inputs[3])[0];

  units::bits tbs(static_cast<unsigned>(in_seg_cfg["TransportBlockLength"][0]));
  if (!tbs.is_byte_exact()) {
    mex_abort("The TBS is not an exact number of bytes.");
  }
  units::bytes tbs_bytes = tbs.round_up_to_bytes();

  in_struct_array                    = inputs[5];
  Struct                   in_buf_id = in_struct_array[0];
  rx_softbuffer_identifier buf_id    = {};
  buf_id.harq_ack_id                 = in_buf_id["HARQProcessID"][0];
  buf_id.rnti                        = in_buf_id["RNTI"][0];

  unsigned nof_codeblocks       = in_buf_id["NumCodeblocks"][0];
  unsigned nof_codeblocks_check = ldpc::compute_nof_codeblocks(tbs, cfg.base_graph);
  if (nof_codeblocks != nof_codeblocks_check) {
    mex_abort("Softbuffer ({}, {}) requested with {} codeblocks, but the codeword has {} codeblocks.",
              buf_id.rnti,
              buf_id.harq_ack_id,
              nof_codeblocks,
              nof_codeblocks_check);
  }

  uint64_t key = static_cast<TypedArray<uint64_t>>(inputs[1])[0];

  unique_rx_softbuffer softbuffer = retrieve_softbuffer(key, buf_id, nof_codeblocks);
  TypedArray<uint8_t>  out        = factory.createArray<uint8_t>({tbs_bytes.value(), 1});
  span<uint8_t>        rx_tb      = to_span(out);

  pusch_decoder_notifier_spy notifier_spy;
  pusch_decoder_buffer&      buffer = decoder->new_data(rx_tb, softbuffer.get(), notifier_spy.get_notifier(), cfg);

  buffer.on_new_softbits(llrs);
  buffer.on_end_softbits();

  outputs[0] = out;

  if (!notifier_spy.has_result()) {
    mex_abort("Notifier result has not been reported.");
  }
  const pusch_decoder_result& dec_result = notifier_spy.get_result();

  StructArray S      = factory.createStructArray({1, 1}, {"crc_ok", "ldpc_iters"});
  S[0]["crc_ok"]     = factory.createScalar(dec_result.tb_crc_ok);
  S[0]["ldpc_iters"] = factory.createScalar(dec_result.ldpc_decoder_stats.get_max());
  outputs[1]         = S;
}

void MexFunction::method_reset_crcs(ArgumentList outputs, ArgumentList inputs)
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
  buf_id.harq_ack_id                       = in_buf_id["HARQProcessID"][0];
  buf_id.rnti                              = in_buf_id["RNTI"][0];

  unsigned nof_codeblocks = in_buf_id["NumCodeblocks"][0];

  uint64_t key = static_cast<TypedArray<uint64_t>>(inputs[1])[0];

  unique_rx_softbuffer softbuffer = retrieve_softbuffer(key, buf_id, nof_codeblocks);
  softbuffer.get().reset_codeblocks_crc();
}

void MexFunction::method_release(ArgumentList outputs, ArgumentList inputs)
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

  uint64_t key = static_cast<TypedArray<uint64_t>>(inputs[1])[0];

  if (storage.release_memento(key) == 0) {
    mex_abort("Something wrong, there was no softbuffer pool with softbufferPoolID {}.", key);
  }
}
