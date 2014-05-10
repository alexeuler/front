class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  MAX_LIKES = 500
  TRIM_THRESHOLD = 100

  has_many :post_likes
  has_many :posts, :through => :post_likes


  def url
    uid = email.split("@")[0]
    "http://vk.com/id#{uid}"
  end

  def like_post(post_id, like_value)
    key = "likes:#{self.id}"
    $redis.hset(key, post_id, "#{like_value}:#{Time.now.to_i}")
    count = $redis.hlen(key)
    trim_likes if count > MAX_LIKES + TRIM_THRESHOLD
  end

  def get_posts_likes(post_ids)
    key = "likes:#{self.id}"
    likes = $redis.hmget(key, post_ids)
    likes.each_with_index { |value, index| likes[index] = value.split(":")[0] if value }
    likes
  end


  def clear_likes
    $redis.del("likes:#{self.id}")
    $redis.del("posts:best:#{self.id}")
  end

  def get_top_posts(count)
    ids = $redis.lrange("posts:best:#{self.id}", 0, count - 1).map(&:to_i)
    $redis.ltrim("posts:best:#{self.id}", count, -1)
    posts = Post.where(id: ids).to_a
    posts.sort_by! { |a| ids.index(a.id) }
    delta = count - posts.count
    min, max = Post.minimum(:id), Post.maximum(:id) if delta > 0
    while delta > 0
      random_ids = (1..delta).map do |i|
        (min + (max - min) * rand()).round(0)
      end
      posts += Post.where(id: random_ids).to_a
      delta = count - posts.count
    end
    posts
  end

  private

  def trim_likes
    key ="likes:#{self.id}"
    hash = $redis.hgetall(key)
    ary = hash.to_a
    ary.sort_by! { |a| -a[1].split(":")[1].to_i }
    ary = ary[0..MAX_LIKES - 1]
    ary.flatten!
    $redis.del(key)
    $redis.hmset(key,ary)
  end


end
