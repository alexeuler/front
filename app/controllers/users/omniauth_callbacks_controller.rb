class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def vkontakte
    info = request.env["omniauth.auth"]
    user = User.where(email: info["uid"] + "@vk.com").first
    user = User.create!(email: info["uid"] + "@vk.com",
                       password: Devise.friendly_token[0, 20],
                       first_name: info["info"]["first_name"],
                       last_name: info["info"]["last_name"],
                       avatar: info["info"]["image"]) if user.nil?
    if user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Vkontakte"
      sign_in_and_redirect user, :event => :authentication
    else
      flash[:notice] = "authentication error"
      redirect_to root_path
    end
  end
end
