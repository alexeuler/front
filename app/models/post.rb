require 'svm/featureable'

class Post < ActiveRecord::Base
  has_one :post_like

  include SVM::Featureable
  self.feature_names = %w(likes_count  likes_age  likes_share
      closed_profiles_share reposts_count text_length
      comments_count log_id attachment_type)
  self.feature_lambdas = {
      text_length: lambda { |x| x.text.length },
      log_id: lambda { |x| Math.log (x.vk_id) }
  }
  self.feature_ordinals = {
      attachment_type: [nil, "graffiti", "audio", "link", "video", "poll", "doc", "photo", "note", "album"]
  }


  def self.ai_picked
    self.includes("post_like").order(likes_count: :desc).limit(10)
  end

  def attachment_vk_url
    attachment_type == "video" ? "http://vk.com/wall#{owner_id}_#{vk_id}"\
            "?z=#{attachment_type}#{attachment_owner_id}_#{attachment_id}" :
        "http://vk.com/#{attachment_type}#{attachment_owner_id}_#{attachment_id}"
  end

  def vk_url
    "http://vk.com/wall#{owner_id}_#{vk_id}"
  end

end
