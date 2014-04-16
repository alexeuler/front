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

end
