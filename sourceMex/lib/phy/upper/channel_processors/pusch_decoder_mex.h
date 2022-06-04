#ifndef SRSGNB_MATLAB_LIB_PHY_UPPER_CHANNEL_PROCESSORS_PUSCH_DECODER_MEX_H
#define SRSGNB_MATLAB_LIB_PHY_UPPER_CHANNEL_PROCESSORS_PUSCH_DECODER_MEX_H

#include "srsgnb/phy/upper/channel_processors/channel_processor_factories.h"
#include "srsgnb/phy/upper/channel_processors/pusch_decoder.h"
#include "srsgnb/phy/upper/rx_softbuffer.h"
#include "srsgnb/phy/upper/rx_softbuffer_pool.h"
#include "srsgnb_matlab/srsgnb_mex_dispatcher.h"
#include "srsgnb_matlab/support/memento.h"

#include <memory>

static std::unique_ptr<srsgnb::pusch_decoder> create_pusch_decoder();

class MexFunction : public srsgnb_mex_dispatcher
{
  class pusch_memento : public memento
  {
  public:
    explicit pusch_memento(std::unique_ptr<srsgnb::rx_softbuffer_pool> p) : pool(std::move(p)){};

    srsgnb::rx_softbuffer* retrieve_softbuffer(const srsgnb::rx_softbuffer_identifier& id, unsigned nof_codeblocks);

  private:
    std::unique_ptr<srsgnb::rx_softbuffer_pool> pool;
  };

public:
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
  }

private:
  srsgnb::rx_softbuffer*
  retrieve_softbuffer(uint64_t key, const srsgnb::rx_softbuffer_identifier& id, unsigned nof_codeblocks);

  void check_step_outputs_inputs(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs);

  void method_new(ArgumentList& outputs, ArgumentList& inputs);

  void method_step(ArgumentList& outputs, ArgumentList& inputs);

  void method_reset_crcs(ArgumentList& outputs, ArgumentList& inputs);

  std::unique_ptr<srsgnb::pusch_decoder> decoder = create_pusch_decoder();

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

#endif // SRSGNB_MATLAB_LIB_PHY_UPPER_CHANNEL_PROCESSORS_PUSCH_DECODER_MEX_H

