require 'libsvm'
module SVM
  class SVM

    def self.load(user)
      Libsvm::Model.load("#{Rails.root}/app/models/#{user.email}")
    end

    def self.to_array(posts)
      result = []
      posts.each do |post|
        vector = []
        FEATURES_NAMES.each do |feature_name|
          lambda = FEATURES_LAMBDAS[feature_name.to_sym]
          value = lambda.nil? ? post[feature_name] : lambda.call(post)
          value.is_a?(Array) ? vector += value : vector << value
        end
        result << vector
      end
      result
    end

    def self.scale(data)
      column_count=data[0].count
      column_count.times do |i|
        column = data.map {|r| r[i]}
        min = column.min
        max = column.max
        data.each do |d|
          d[i] = max == min ? 0 : (d[i] - min) / (max - min)
        end
      end
      data
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
  end
end