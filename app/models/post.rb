class Post < ActiveRecord::Base

  def self.ai_picked
    self.where(attachment_type:"video").limit(10)
  end

end
