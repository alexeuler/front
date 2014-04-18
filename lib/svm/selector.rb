require_relative "svm"

module SVM
  class Selector

    MAX_TRAINING = 100
    POSTS_PER_PAGE = 10
    MAX_SAMPLING_TRIES = 3

    def self.select(user)
      labels, posts = self.get_training_sample(user)
      svm = Svm.new user: user
      trained = (labels.count != 0)
      svm.train(labels, posts) if trained
      training_progress = [labels.count.to_f / MAX_TRAINING, 1].min

      sample, tries = [], 0
      begin
        tries +=1
        sample+= pick_posts_sample(excluding: posts.map(&:id))
        sample.delete_if { |x| svm.predict_probability(x) == 0 && rand <=training_progress } if trained
      end while sample.count < POSTS_PER_PAGE && tries <= MAX_SAMPLING_TRIES

      extracted=extract_posts_from_sample(sample)
      ids = extracted.map(&:id)
      nullify_likes(user.id, ids)
      Post.includes(:post_like).where(id: ids).to_a
    end

    private

    def self.get_training_sample(user)
      posts = Post.includes(:post_like).where(post_likes: {user_id: user.id}).to_a
      labels = posts.map { |p| p.post_like.value }
      [labels, posts]
    end

    def self.nullify_likes(user_id, post_ids)
      post_ids.each do |id|
        like = PostLike.where(user_id: user_id, post_id: id).first_or_initialize
        like.value = 0
        like.save
      end
    end

    def self.pick_posts_sample(args = {})
      excluding = args[:excluding] || []
      count = args[:count] || 1000
      klass = excluding.empty? ? Post : Post.where("id not in (?)", excluding)
      klass.order("random()").limit(count).to_a
    end

    def self.extract_posts_from_sample(sample)
      sorted = sample.sort_by(&:likes_count)
      step = sorted.length.to_f / POSTS_PER_PAGE
      result = []
      (0..POSTS_PER_PAGE-1).each do |i|
        result << sorted[(i * step).floor]
      end
      result
    end

  end


end