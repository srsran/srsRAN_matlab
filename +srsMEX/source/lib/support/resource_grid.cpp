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

/// \file
/// \brief Definition of resource-grid utilities.

#include "srsran_matlab/support/resource_grid.h"
#include "srsran_matlab/support/factory_functions.h"
#include "srsran_matlab/support/to_span.h"
#include "srsran/phy/support/resource_grid_writer.h"

using namespace matlab::data;
using namespace srsran;
using namespace srsran_matlab;

std::unique_ptr<resource_grid> srsran_matlab::read_resource_grid(const TypedArray<srsran::cf_t>& in_grid)
{
  const ArrayDimensions grid_dims       = in_grid.getDimensions();
  unsigned              nof_subcarriers = grid_dims[0];
  unsigned              nof_symbols     = grid_dims[1];
  unsigned              nof_rx_ports    = 1;
  if (grid_dims.size() == 3) {
    nof_rx_ports = grid_dims[2];
  }

  std::unique_ptr<resource_grid> grid = create_resource_grid(nof_subcarriers, nof_symbols, nof_rx_ports);
  if (!grid) {
    return nullptr;
  }

  span<const cf_t> grid_view = to_span(in_grid);

  unsigned remaining_res = in_grid.getNumberOfElements();
  for (unsigned i_port = 0; i_port != nof_rx_ports; ++i_port) {
    for (unsigned i_symbol = 0; i_symbol != nof_symbols; ++i_symbol) {
      span<const cf_t> symbol_view = grid_view.first(nof_subcarriers);
      remaining_res -= nof_subcarriers;
      grid_view = grid_view.last(remaining_res);

      grid->get_writer().put(i_port, i_symbol, 0, symbol_view);
    }
  }

  return grid;
}
