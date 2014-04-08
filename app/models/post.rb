class Post < ActiveRecord::Base

  def self.ai_picked
    self.limit(10)
  end

end
