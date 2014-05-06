class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  has_many :post_likes
  has_many :posts, :through => :post_likes


  def url
    uid = email.split("@")[0]
    "http://vk.com/id#{uid}"
  end

  def like_post(post_id, like_value)
    member = "#{post_id}:#{like_value}"
    score = Time.now.to_i
    key = "likes:#{self.id}"
    $redis.zadd(key, score, member)
  end

  def clear_likes
    key = "likes:#{self.id}"
    $redis.zremrangebyrank(key, 0, -1)
  end

  def get_top_posts(count)
    ids = $redis.lrange("posts:best:#{self.id}", 0, count - 1).map(&:to_i)
    $redis.ltrim("posts:best:#{self.id}", 0, count - 1)
    posts = Post.where(id: ids).to_a
    delta = count - posts.count
    min, max = Post.minimum(:id), Post.maximum(:id) if delta > 0
    while delta > 0
      random_ids = delta.times do |i|
        (min + (max - min) * rand()).round(0)
      end
      posts += Post.where(id: random_ids).to_a
      delta = count - posts.count
    end
    posts
  end

end
