require 'libsvm'
module SVM
  class Svm

    PATH = "#{Rails.root}/app/svm_models/"
    class SVMError < RuntimeError
    end

    def self.load(user)
      model = Libsvm::Model.load("#{Path}#{user.email}")
      self.new(model: model, user: user)
    end

    def initialize(args = {})
      @model = args[:model]
      @user = args[:user]
    end

    def save
      @model.save("#{Path}#{@user.email}")
    end

    def train(labels, models_or_features)
      raise SVMError, "Empty train set is not allowed" if models_or_features.nil? || models_or_features.empty?
      raise SVMError, "Labels and features size mismatch" unless labels.count == models_or_features.count
      features = extract_features(models_or_features)
      find_extremes(features)
      features.map! {|f| scale(f)}
      features.map! {|f| Libsvm::Node.features(f)}
      problem = Libsvm::Problem.new
      parameter = Libsvm::SvmParameter.new
      parameter.cache_size = 1 # in megabytes
      parameter.eps = 0.001
      parameter.c = 10
      problem.set_examples(labels, features)
      @model = Libsvm::Model.train(problem, parameter)
    end

    def predict_probability(model_or_feature)
      raise SVMError, "Nil feature is not allowed" if model_or_feature.nil?
      raise SVMError, "Model is not defined" if @model.nil?
      feature = extract_features(model_or_feature)[0]
      feature = Libsvm::Node.features(feature)
      result = @model.predict_probability(feature)
      result[1][1]
    end

    private

    def find_extremes(features)
      size = features[0].length
      @min_vector = features[0].clone
      @max_vector = features[0].clone
      features.each do |feature|
        (0..size-1).each do |i|
          @max_vector[i] = feature[i] if feature[i] > @max_vector[i]
          @min_vector[i] = feature[i] if feature[i] < @min_vector[i]
        end
      end
    end

    def scale(feature)
      result = []
      size = feature.length
      (0..size-1).each do |i|
        # note that if the vector outside training set contains new feature value
        # (and training set contained only one other value) it'll be ignored
        result << @max_vector[i] == @min_vector[i] ? @max_vector[i] : (feature[i] - @min_vector[i]).to_f / (@max_vector[i] - @min_vector[i])
      end
      result
    end

    def extract_features(models_or_features)
      models_or_features = models_or_features.is_a?(Array) ? models_or_features : [models_or_features]
      features = models_or_features[0].is_a?(Array) ? models_or_features :
          models_or_features.map(&:to_feature)
      size = features[0].length
      features.each { |f| raise "Features of different length in array." unless f.length == size }
      features
    end
  end
end