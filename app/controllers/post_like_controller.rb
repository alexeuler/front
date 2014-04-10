class PostLikeController < ApplicationController
  def update
    user_id = current_user.id
    post_id = params[:post_id].to_i
    @post_like = PostLike.where(user_id: user_id, post_id: post_id).first_or_initialize
    @post_like.value = params[:value].to_i
    @post_like.save
    render json: {status:"Ok"}
  end
end
