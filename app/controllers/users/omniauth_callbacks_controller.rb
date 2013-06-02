class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def github
    @user = User.find_github(request.env["omniauth.auth"], current_user)
    @user.update_attribute(:github_id, request.env["omniauth.auth"].credentials.token)
    print request.env["omniauth.auth"].credentials.token
    sign_in_and_redirect @user, :event => :authentication
    set_flash_message(:notice, :success, :kind => "Github") if is_navigational_format?
  end

end
