# encoding: utf-8

def frozen_double(name = nil, options = {})
  double name, options.merge(freeze: nil, frozen?: true)
end
