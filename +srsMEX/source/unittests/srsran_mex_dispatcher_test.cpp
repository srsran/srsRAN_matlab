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
/// \brief srsran_mex_dispatcher unit test.
///
/// This file defines a class that derives from srsran_mex_dispatcher with two simple methods. Once the mex is built,
/// the user should check its behavior from the MATLAB shell.

#include "srsran_matlab/srsran_mex_dispatcher.h"

#include <map>

using namespace matlab::data;
using matlab::mex::ArgumentList;

/// Example MexFunction class inherited from srsran_mex_dispatcher.
class MexFunction : public srsran_mex_dispatcher
{
public:
  /// \brief Constructor.
  ///
  /// It creates two identifier&ndash;method pairs for the dispatcher, "one"&ndash;method_one and
  /// "two"&ndash;method_two.
  MexFunction()
  {
    create_callback("one", [this](ArgumentList& out, ArgumentList& in) { return this->method_one(out, in); });
    create_callback("two", [this](ArgumentList& out, ArgumentList& in) { return this->method_two(out, in); });
  }

private:
  /// Prints a string identifying the method and the second input (it should be a scalar double).
  void method_one(ArgumentList& outputs, ArgumentList& inputs);
  /// Prints a string identifying the method and the second input (it should be a scalar double).
  void method_two(ArgumentList& outputs, ArgumentList& inputs);
};

void MexFunction::method_one(ArgumentList& outputs, ArgumentList& inputs)
{
  if (inputs.size() != 2) {
    mex_abort("Wrong number of inputs.");
  }
  if (inputs[1].getType() != ArrayType::DOUBLE) {
    mex_abort("Input must be a scalar double.");
  }

  double in = static_cast<TypedArray<double>>(inputs[1])[0];
  std::cout << "This is method one with input " << in << ".\n";
  outputs[0] = factory.createScalar(in + 1);
}

void MexFunction::method_two(ArgumentList& outputs, ArgumentList& inputs)
{
  if (inputs.size() != 2) {
    mex_abort("Wrong number of inputs.");
  }
  if (inputs[1].getType() != ArrayType::DOUBLE) {
    mex_abort("Input must be a scalar double.");
  }

  double in = static_cast<TypedArray<double>>(inputs[1])[0];
  std::cout << "This is method two with input " << in << ".\n";
  outputs[0] = factory.createScalar(in + 2);
}
