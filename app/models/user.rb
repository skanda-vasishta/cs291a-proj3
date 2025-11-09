class User < ApplicationRecord
  has_secure_password

  before_validation :normalize_username
  before_create :set_last_active_at

  validates :username, presence: true,
                       uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }

  private

  def normalize_username
    return if username.blank?

    self.username = username.to_s.strip.downcase
  end

  def set_last_active_at
    self.last_active_at ||= Time.current
  end
end
