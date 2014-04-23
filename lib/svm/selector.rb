require_relative "svm"

module SVM
  class Selector

    MAX_TRAINING = 100
    POSTS_PER_PAGE = 10
    MAX_SAMPLING_TRIES = 1

    def self.select(user)
      labels, posts = self.get_training_sample(user)
      svm = Svm.new user: user
      trained = (labels.count != 0)
      svm.train(labels, posts) if trained
      training_progress = [labels.count.to_f / MAX_TRAINING, 1].min

      selection, tries = [], 0
      post_ids = posts.map(&:id)
      picked = []
      if trained
        begin
          tries +=1
          picked = pick_sample(excluding: post_ids)
          filtered = picked.map do |post|
            forecast = svm.predict_probability(post)
            forecast[:label] == 0 ? nil : {post: post, prob: forecast[:prob]}
          end
          #ToDo picked is empty, add random sample
          filtered.compact!
          selection+= filtered
        end while selection.count < POSTS_PER_PAGE && tries <= MAX_SAMPLING_TRIES
      end
      selection.sort { |a, b| b[:prob] <=> a[:prob] }
      extracted= selection.first(POSTS_PER_PAGE * training_progress)
      picked = pick_sample(excluding: post_ids) if picked.empty?
      sample = picked.sample(POSTS_PER_PAGE - extracted.count).map { |x| {post: x, prob: 0} }
      extracted += sample
      ids = extracted.map { |tuple| tuple[:post].id }
      nullify_likes(user.id, ids)
      Post.includes(:post_like).where(id: ids).order(likes_count: :desc).to_a
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

    def self.pick_sample(args = {})
      excluding = args[:excluding] || []
      count = args[:count] || 1000
      klass = excluding.empty? ? Post : Post.where("id not in (?)", excluding)
      klass.order("random()").limit(count).to_a
    end

    def self.select_posts_from_sample(sample)
      sorted = sample.sort { |a, b| b.likes_count <=> a.likes_count }
      step = sorted.length.to_f / POSTS_PER_PAGE
      result = []
      (0..POSTS_PER_PAGE-1).each do |i|
        result << sorted[(i * step).floor]
      end
      result
    end

  end


end