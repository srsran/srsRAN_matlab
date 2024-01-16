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
/// \brief Utilities to create spans from MATLAB types.

#pragma once

#include "srsran/adt/span.h"
#include "MatlabDataArray/TypedArray.hpp"

namespace srsran_matlab {

// NOLINTBEGIN(cppcoreguidelines-pro-type-reinterpret-cast)

/// \brief Creates a read&ndash;write span from a MATLAB TypedArray.
///
/// The output span is a view over the memory traversed by the \c typed_array default iterator.
///
/// \tparam ArrayType  Value type of the input \c TypedArray.
/// \tparam SpanType   Value type of the output span.
///
/// \warning An assertion is raised if \c ArrayType cannot be converted to \c SpanType.
template <typename ArrayType, typename SpanType = ArrayType>
srsran::span<SpanType> to_span(matlab::data::TypedArray<ArrayType>& typed_array)
{
  static_assert(std::is_convertible<ArrayType, SpanType>::value, "ArrayType cannot be converted to SpanType.");

  return {reinterpret_cast<SpanType*>(&(*typed_array.begin())), reinterpret_cast<SpanType*>(&(*typed_array.end()))};
}

/// \brief Creates a read-only span from a MATLAB TypedArray.
///
/// The output span is a view over the memory traversed by the \c typed_array default iterator.
///
/// \tparam ArrayType  Value type of the input \c TypedArray.
/// \tparam SpanType   Value type of the output span.
///
/// \warning An assertion is raised if \c ArrayType cannot be converted to \c SpanType.
template <typename ArrayType, typename SpanType = ArrayType>
srsran::span<const SpanType> to_span(const matlab::data::TypedArray<ArrayType>& typed_array)
{
  static_assert(std::is_convertible<ArrayType, SpanType>::value, "ArrayType cannot be converted to SpanType.");

  return {reinterpret_cast<const SpanType*>(&(*typed_array.cbegin())),
          reinterpret_cast<const SpanType*>(&(*typed_array.cend()))};
}

// NOLINTEND(cppcoreguidelines-pro-type-reinterpret-cast)

} // namespace srsran_matlab
