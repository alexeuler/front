require "libsvm"
module SVM
  module Featureable

    module ClassMethods
      attr_accessor :feature_lambdas
      attr_reader :feature_names, :feature_ordinals

      def feature_names=(names)
        @feature_names = names.map(&:to_sym)
        @feature_names = feature_ordinals.nil? ? @feature_names : @feature_names - feature_ordinals.keys.map(&:to_sym)
      end

      def feature_ordinals=(ordinals)
        @feature_ordinals = ordinals
        @feature_names = feature_ordinals.nil? ? @feature_names : @feature_names - feature_ordinals.keys.map(&:to_sym)
      end

    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def to_feature
      feature_ordinals = self.class.feature_ordinals
      feature_lambdas = self.class.feature_lambdas
      feature_names = self.class.feature_names
      ary = []
      #ToDo - assign whole attributes to ary, except lambdas and ordinals
      feature_names.each do |name|
        value = self.send(name)
        value = feature_lambdas[name].call(value) if feature_lambdas and feature_lambdas.keys.include?(name)
        ary << (value || 0)
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