require 'libsvm'
module SVM
  class SVM

    FEATURES_NAMES = %w(likes_count  likes_age  likes_share
      closed_profiles_share reposts_count text_length
      comments_count log_id attachment_type)

    FEATURES_LAMBDAS = {
        text_length: lambda {|x| x.text.length},
        log_id: lambda {|x| Math.log (x.vk_id)},
        attachment_type: lambda do |x|
          names = %w(graffiti audio link video poll doc photo note album)
          result = Array.new(names.count + 1, 0)
          index = names.index(x.attachment_type) || result.length - 1
          result[index] = 1
          result
        end
    }

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