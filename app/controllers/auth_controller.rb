class AuthController < ApplicationController
  before_action :require_session_user!, only: %i[logout refresh me]

  def register
    user = User.new(register_params)

    if user.save
      establish_session_for(user)
      render json: auth_response(user), status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(username: login_params[:username].to_s.strip.downcase)

    if user&.authenticate(login_params[:password])
      establish_session_for(user)
      render json: auth_response(user), status: :ok
    else
      render_invalid_credentials
    end
  end

  def logout
    clear_session
    render json: { message: "Logged out successfully" }, status: :ok
  end

  def refresh
    user = current_user
    user.touch(:last_active_at)
    render json: auth_response(user), status: :ok
  end

  def me
    render json: user_payload(current_user), status: :ok
  end

  private

  def register_params
    base_params.permit(:username, :password, :password_confirmation)
  end

  def login_params
    base_params.permit(:username, :password)
  end

  def base_params
    return params.require(:user) if params[:user].present?

    ActionController::Parameters.new(
      user: {
        username: params[:username],
        password: params[:password],
        password_confirmation: params[:password_confirmation]
      }.compact_blank
    ).require(:user)
  end
end

