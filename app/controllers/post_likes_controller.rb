class PostLikesController < ApplicationController
  def update
    post_id = params[:post_id].to_i
    like_value = params[:value].to_i
    current_user.like_post(post_id, like_value)
    render json: {status:"Ok"}
  end

  def destroy
    current_user.clear_likes
    render json: {status:"Ok"}
  end
end
