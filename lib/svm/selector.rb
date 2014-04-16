require_relative "svm"

module SVM
  class Selector

    MAX_TRAINING = 100
    POSTS_PER_PAGE = 10

    def self.select(user)
      posts = Post.includes(:post_like).where('"post_likes".user_id = ?', user.id).to_a
      svm = Svm.new user: user
      labels = posts.map {|p| p.post_like.value}
      svm.train(labels, posts)
      trained_ids = posts.map(&:id)
      untrained = trained_ids.empty? ? Post.all.to_a : Post.where("id not in (?)", trained_ids).to_a
      predicted = untrained.map {|p| [svm.predict_probability(p), p.id]}
      predicted.sort!
      svm_posts_number = ([posts.count.to_f / MAX_TRAINING, 1].min * POSTS_PER_PAGE).round(0)
      #TODO add posts count limit here
      result = []
      svm_posts_number.times {result << predicted.pop}
      predicted.shuffle!
      (POSTS_PER_PAGE - svm_posts_number).times do
        item = predicted.pop
        like = PostLike.where(user_id: user.id, post_id: item[1]).first_or_initialize
        like.value = 0
        like.save
        result << item
      end
      ids = result.map {|x| x[1]}
      Post.includes(:post_like).where(id: ids).to_a
    end
  end
end