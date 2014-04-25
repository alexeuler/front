require 'libsvm'
module SVM
  class Svm

    PATH = "#{Rails.root}/app/svm_models/"
    DEFAULT_C = 11
    DEFAULT_GAMMA = 62
    LOG_ACCURACY = true

    class SVMError < RuntimeError
    end

    def self.load(user)
      model = Libsvm::Model.load("#{PATH}#{user.email}")
      self.new(model: model, user: user)
    end

    def initialize(args = {})
      @model = args[:model]
      @user = args[:user]
    end

    def save
      @model.save("#{PATH}#{@user.email}")
    end

    def train(labels, models_or_features)
      raise SVMError, "Empty train set is not allowed" if models_or_features.nil? || models_or_features.empty?
      raise SVMError, "Labels and features size mismatch" unless labels.count == models_or_features.count
      features = extract_features(models_or_features)
      find_extremes(features)
      features.map! { |f| scale(f) }
      features.map! { |f| Libsvm::Node.features(f) }
      problem = Libsvm::Problem.new
      problem.set_examples(labels, features)
      param = get_param
      if LOG_ACCURACY
        accuracy = cross_validate labels: labels, features: features,
                                  chunk_size: [labels.count / 10, 1].max, c: param.c, gamma: param.gamma
        puts "\n#######Accuracy: #{accuracy} #######\n"
      end
      @model = Libsvm::Model.train(problem, param)
    end

    def predict_probability(model_or_feature)
      raise SVMError, "Nil feature is not allowed" if model_or_feature.nil?
      raise SVMError, "Model is not defined" if @model.nil?
      feature = extract_features([model_or_feature])[0]
      feature = scale(feature)
      feature = Libsvm::Node.features(feature)
      result = @model.predict_probability(feature)
      {label: result[0], prob: result[1].max}
    end

    private

    def get_param(args = {})
      labels = args[:labels]
      features = args[:features]
      best = labels.nil? ? {params: [DEFAULT_C, DEFAULT_GAMMA]} : find_optimal_parameters(labels, features)
      rbf_parameter(best[:params][0], best[:params][1])
    end

    def find_optimal_parameters(labels, features)
      best = {params: [], accuracy: 0}
      cs.each do |c|
        gammas.each do |gamma|
          accuracy = cross_validate labels: labels, features: features,
                                    chunk_size: [labels.count / 10, 1].max, c: c, gamma: gamma
          if accuracy > best[:accuracy]
            best[:accuracy] = accuracy
            best[:params] = [c, gamma]
          end
        end
      end
      best
    end


    def gammas
      result = []
      7.times do |i|
        result << 2 ** (i - 3)
      end
      result
    end

    def cs
      gammas
    end

    def rbf_parameter(c, gamma)
      parameter = Libsvm::SvmParameter.new
      parameter.cache_size = 1 # in megabytes
      parameter.gamma = gamma
      parameter.eps = 0.01
      parameter.c = c
      parameter.probability = 1
      parameter.kernel_type = Libsvm::KernelType::RBF
      parameter
    end

    def cross_validate(args = {})
      labels = args[:labels]
      features = args[:features]
      chunk_size = args[:chunk_size]
      c = args[:c]
      gamma = args[:gamma]
      steps = (labels.count - 1) / chunk_size + 1
      errors = 0
      steps.times do |i|
        training_features = features.clone
        training_labels = labels.clone
        test_features = training_features.slice!(i * chunk_size, chunk_size)
        test_labels = training_labels.slice!(i * chunk_size, chunk_size)
        problem = Libsvm::Problem.new
        problem.set_examples(training_labels, training_features)
        param = rbf_parameter(c, gamma)
        model = Libsvm::Model.train(problem, param)
        test_labels.count.times do |i|
          errors +=1 unless test_labels[i] == model.predict(test_features[i])
        end
      end
      1 - errors.to_f / labels.count
    end


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
        value = @max_vector[i] == @min_vector[i] ? @max_vector[i] : (feature[i] - @min_vector[i]).to_f / (@max_vector[i] - @min_vector[i])
        result << value
      end
      result
    end

    def extract_features(models_or_features)
      features = models_or_features[0].is_a?(Array) ? models_or_features :
          models_or_features.map(&:to_feature)
      size = features[0].length
      features.each { |f| raise "Features of different length in array." unless f.length == size }
      features
    end
  end
end