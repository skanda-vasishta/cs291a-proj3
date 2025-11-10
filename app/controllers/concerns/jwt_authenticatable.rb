module JwtAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_with_jwt!
  end

  private

  def authenticate_with_jwt!
    payload = decode_jwt_from_header
    @current_user = User.find_by(id: payload[:user_id]) if payload
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id].present?
    return if @current_user

    render(json: { error: "Unauthorized" }, status: :unauthorized) && return
  rescue JwtService::DecodeError
    render(json: { error: "Invalid or expired token" }, status: :unauthorized) && return
  end

  def decode_jwt_from_header
    header = request.headers["Authorization"]
    return if header.blank?

    prefix, token = header.split(" ")
    return unless prefix.casecmp("Bearer").zero? && token.present?

    JwtService.decode(token)
  end
end

