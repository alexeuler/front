class Post < ActiveRecord::Base

  def self.ai_picked
    self.order(likes_count: :desc).limit(10)
  end

end
