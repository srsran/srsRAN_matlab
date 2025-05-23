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
/// \brief MexFunction template.

#pragma once

#include <cstdint> // Needed because not included in mex.hpp.
#include <iterator>
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wsuggest-override"
#include "mex.hpp"
#pragma GCC diagnostic pop

#include "mexAdapter.hpp"
#include <fmt/format.h>
#include <map>

/// \brief MexFunction template.
///
/// Common template for MexFunction: the () operator is a simpler dispatcher that calls the method identified by the
/// first input. A MexFunction that inherits from this template should establish the identifier&ndash;method pairs
/// in the constructor.
///
/// All the methods managed by the dispatcher should take the same arguments as srsran_mex_dispatcher::operator()().
class srsran_mex_dispatcher : public matlab::mex::Function
{
public:
  /// Alias for MATLAB type.
  using ArgumentList = matlab::mex::ArgumentList;

  /// \brief Function call operator.
  ///
  /// The operator () works as a dispatcher: it calls the method identified by the first input, forwards the rest of
  /// inputs to it and gathers its outputs.
  /// \param[out] outputs  A MATLAB argument list of output parameters.
  /// \param[in]  inputs   A MATLAB argument list of input parameters. The first input must be a string identifying a
  ///                      method of derived class.
  void operator()(ArgumentList outputs, ArgumentList inputs) override
  {
    using namespace matlab::data;

    if (inputs[0].getType() != ArrayType::CHAR) {
      mex_abort("First input must be a char.");
    }

    std::string action_name = static_cast<CharArray>(inputs[0]).toAscii();

    auto action_iter = callbacks.find(action_name);
    if (action_iter == callbacks.end()) {
      mex_abort("Unknown action: " + action_name + ".");
    }

    action_iter->second(outputs, inputs);
  }

protected:
  /// \brief Links a method to an identifier.
  ///
  /// Stores an association between string identifier \c name and the method \c fnc.
  void create_callback(const std::string& name, const std::function<void(ArgumentList, ArgumentList)>& fnc)
  {
    auto action_iter = callbacks.find(name);
    if (action_iter != callbacks.end()) {
      mex_abort("Action " + name + " already exists.");
    }
    callbacks.emplace(name, fnc);
  }

  /// \brief Calls MATLAB \c error function.
  /// \param[in] msg  Error message.
  void mex_abort(const std::string& msg)
  {
    using namespace matlab::data;
    // clang-format off
    matlabPtr->feval(u"error", 0, std::vector<Array>({factory.createScalar(msg)}));
    // clang-format on
  }

  /// \brief Calls MATLAB \c error function.
  /// \param[in] fmtstr  Format string.
  template <typename... Args>
  void mex_abort(const char* fmtstr, Args&&... args)
  {
    fmt::memory_buffer buffer;
    fmt::format_to(std::back_inserter(buffer), fmtstr, std::forward<Args>(args)...);
    mex_abort(to_string(buffer));
  }

  /// A MATLAB array factory for array creation.
  matlab::data::ArrayFactory factory;

private:
  /// Container of the identifier&ndash;method pairs.
  std::map<std::string, std::function<void(ArgumentList, ArgumentList)>> callbacks;
  /// Engine to access the MATLAB shell.
  std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
};
