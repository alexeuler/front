require "libsvm"
module SVM
  module Featureable

    module ClassMethods
      attr_accessor :feature_names, :feature_lambdas, :feature_ordinals
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def to_feature
      feature_ordinals = self.class.feature_ordinals
      feature_names= self.class.feature_names && self.class.feature_names.map(&:to_sym)
      feature_lambdas = self.class.feature_lambdas
      names = feature_ordinals.nil? ? feature_names : feature_names - feature_ordinals.keys.map(&:to_sym)
      ary = []
      names.each do |name|
        value = self.send(name)
        value = feature_lambdas[name].call(value) if feature_lambdas and feature_lambdas.keys.include?(name)
        ary << value
      end
      feature_ordinals.each_pair do |name, states|
        value = self.send(name)
        index = states.index(value)
        vector = Array.new(states.count, 0)
        vector[index] = 1 if index
        ary += vector
      end if feature_ordinals
      ary
    end

  end
end