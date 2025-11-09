class ApplicationController < ActionController::API
  include ActionController::Cookies

  private

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = User.find_by(id: session[:user_id])
  end

  def require_session_user!
    return if current_user.present?

    render json: { error: "No session found" }, status: :unauthorized
  end

  def establish_session_for(user)
    session[:user_id] = user.id
    user.update!(last_active_at: Time.current)
  end

  def clear_session
    reset_session
  end

  def render_invalid_credentials
    render json: { error: "Invalid username or password" }, status: :unauthorized
  end

  def user_payload(user)
    {
      id: user.id,
      username: user.username,
      created_at: user.created_at.iso8601,
      last_active_at: user.last_active_at&.iso8601,
      updated_at: user.updated_at.iso8601
    }
  end

  def auth_response(user)
    {
      user: user_payload(user),
      token: JwtService.encode({ user_id: user.id })
    }
  end
end
