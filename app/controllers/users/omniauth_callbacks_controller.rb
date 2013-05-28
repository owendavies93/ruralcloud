class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def github
    @user = User.find_github(request.env["omniauth.auth"], current_user)

    sign_in_and_redirect @user, :event => :authentication
    set_flash_message(:notice, :success, :kind => "Github") if is_navigational_format?
  end

end
