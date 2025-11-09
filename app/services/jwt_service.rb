class JwtService
  class DecodeError < StandardError; end

  ALGORITHM = "HS256"
  DEFAULT_EXPIRY = 24.hours

  class << self
    def encode(payload, exp: DEFAULT_EXPIRY.from_now)
      payload = payload.dup
      payload[:exp] = exp.to_i
      JWT.encode(payload, secret_key, ALGORITHM)
    end

    def decode(token)
      body, = JWT.decode(token, secret_key, true, { algorithm: ALGORITHM })
      HashWithIndifferentAccess.new(body)
    rescue JWT::DecodeError => e
      raise DecodeError, e.message
    end

    private

    def secret_key
      Rails.application.credentials.dig(:jwt_secret) || Rails.application.secret_key_base
    end
  end
end

