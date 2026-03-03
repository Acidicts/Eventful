class SessionsController < ApplicationController
  # omniauth callback typically comes as a GET, which doesn't include a CSRF token
  skip_before_action :verify_authenticity_token, only: :create

  def create
    auth = request.env["omniauth.auth"]
    user = User.from_omniauth(auth)
    session[:user_id] = user.id
    redirect_to root_path, notice: "Signed in successfully"
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path, notice: "Signed out"
  end
end
