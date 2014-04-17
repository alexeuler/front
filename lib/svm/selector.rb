require_relative "svm"

module SVM
  class Selector

    MAX_TRAINING = 100
    POSTS_PER_PAGE = 10

    def self.select(user)
      labels, posts = self.get_training_sample(user)

      if labels.count == 0
        sample = get_untrained_sample
        items = pick_random_items(sample, POSTS_PER_PAGE)
        ids = items.map(&:id)
        nullify_likes(user.id, ids)
        return Post.includes(:post_like).where(id: ids).to_a
      end

      svm = Svm.new user: user
      svm.train(labels, posts)

      untrained_sample = get_untrained_sample(posts)
      probabilities = untrained_sample.map { |p| [svm.predict_probability(p), p.id] }
      probabilities.sort!
      suggested_posts_number = ([posts.count.to_f / MAX_TRAINING, 1].min * POSTS_PER_PAGE).round(0)
      result_count = POSTS_PER_PAGE
      result = []
      suggested_posts_number.times do
        break if probabilities.count == 0
        result << predicted.pop
        result_count -= 1
      end

      result += self.pick_random_items(predicted, result_count)

      ids = result.map { |x| x[1] }
      nullify_likes(user.id, ids)
      Post.includes(:post_like).where(id: ids).to_a
    end

    private

    def self.get_training_sample(user)
      posts = Post.includes(:post_like).where(post_likes: {user_id: user.id}).to_a
      labels = posts.map { |p| p.post_like.value }
      [labels, posts]
    end

    def self.get_untrained_sample(trained_sample = [])
      return Post.all.to_a if trained_sample.nil? or trained_sample.empty?
      trained_ids = trained_sample.map(&:id)
      Post.where("id not in (?)", trained_ids).to_a
    end

    def self.get_untrained_sample_ids(trained_sample = [])
      return Post.select(:id).all.to_a if trained_sample.nil? or trained_sample.empty?
      trained_ids = trained_sample.map(&:id)
      Post.where("id not in (?)", trained_ids).to_a
    end


    def self.pick_random_items(array, n)
      array.shuffle!
      result = []
      n.times do
        break if array.count == 0
        item = array.pop
        result << item
      end
      result
    end

    def self.nullify_likes(user_id, post_ids)
      post_ids.each do |id|
        like = PostLike.where(user_id: user_id, post_id: id).first_or_initialize
        like.value = 0
        like.save
      end
    end

  end


end