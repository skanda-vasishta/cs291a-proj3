class JwtService
  class DecodeError < StandardError; end

  ALGORITHM = "HS256"
  DEFAULT_EXPIRY = 24.hours

  class << self
    def encode(payload, exp: DEFAULT_EXPIRY.from_now)
      claims = normalize_payload(payload)
      claims[:exp] = exp.to_i
      JWT.encode(claims, secret_key, ALGORITHM)
    end

    def decode(token)
      body, = JWT.decode(token, secret_key, true, { algorithm: ALGORITHM })
      HashWithIndifferentAccess.new(body)
    rescue JWT::DecodeError => e
      raise DecodeError, e.message
    end

    private

    def normalize_payload(payload)
      if payload.is_a?(Hash)
        payload.deep_dup.symbolize_keys
      elsif payload.respond_to?(:to_h)
        payload.to_h.symbolize_keys
      elsif payload.respond_to?(:id)
        { user_id: payload.id }
      else
        raise ArgumentError, "Unsupported payload type for JWT encoding"
      end
    end

    def secret_key
      Rails.application.credentials.dig(:jwt_secret) || Rails.application.secret_key_base
    end
  end
end

