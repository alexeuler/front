require "libsvm"
module SVM
  module Featureable

    attr_accessor :feature_names, :feature_lambdas, :feature_ordinals

    def to_feature
      names = feature_names - feature_ordinals
      ary = []
      names.each do |name|
        name = name.to_sym
        value = self.send(name)
        value = feature_lambdas[name].call(value) if feature_lambdas.keys.include?(name)
        ary << value
      end
      feature_ordinals.each_pair do |name, states|
        name = name.to_sym
        value = self.send(name)
        index = states.index(value)
        vector = Array.new(states.count, 0)
        vector[index] = 1
        ary += vector
      end
      ary
    end

  end
end