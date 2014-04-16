require 'libsvm'
module SVM
  class SVM

    def self.load(user)
      Libsvm::Model.load("#{Rails.root}/app/models/#{user.email}")
    end

    def self.scale(models_or_features)
      features = extract_features(models_or_features)
      size = features[0].length
      min_vector = features[0].clone
      max_vector = features[0].clone
      features.each do |feature|
        (0..size-1).each do |i|
          max_vector[i] = feature[i] if feature[i] > max_vector[i]
          min_vector[i] = feature[i] if feature[i] < min_vector[i]
        end
      end
      features.each do |feature|
        (0..size-1).each do |i|
          feature[i] = (feature[i] - min_vector[i]).to_f / (max_vector[i] - min_vector[i]) unless max_vector[i] == min_vector[i]
        end
      end
    end

    def self.train(posts)
      problem = Libsvm::Problem.new
      parameter = Libsvm::SvmParameter.new
      parameter.cache_size = 1 # in megabytes
      parameter.eps = 0.001
      parameter.c = 10
      problem.set_examples(labels, examples)
      @model = Libsvm::Model.train(problem, parameter)
    end

    private

    def self.extract_features(models_or_features)
      models_or_features = models_or_features.is_a?(Array) ? models_or_features : [models_or_features]
      features = models_or_features[0].is_a?(Array) ? models_or_features :
          models_or_features.map(&:to_feature)
      size = features[0].length
      features.each {|f| raise "Features of different length in array." unless f.length == size}
      features
    end
  end
end