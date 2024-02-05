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
/// \brief Declaration of resource-grid utilities.

#pragma once

#include "MatlabDataArray.hpp"
#include "srsran/adt/complex.h"
#include "srsran/phy/support/resource_grid.h"

namespace srsran_matlab {

/// \brief Creates a resource grid from a MATLAB multidimensional array.
///
/// \param[in] in_grid  The resource grid as a multidimensional (2D or 3D) array of complex floats, as passed by MATLAB
///                     to the MEX.
/// \return A unique pointer to the newly created resource grid object.
std::unique_ptr<srsran::resource_grid> read_resource_grid(const matlab::data::TypedArray<srsran::cf_t>& in_grid);

} // namespace srsran_matlab
