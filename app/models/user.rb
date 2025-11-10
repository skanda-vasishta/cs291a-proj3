class User < ApplicationRecord
  has_secure_password

  has_many :initiated_conversations,
           class_name: "Conversation",
           foreign_key: :initiator_id,
           inverse_of: :initiator,
           dependent: :destroy
  has_many :assigned_conversations,
           class_name: "Conversation",
           foreign_key: :assigned_expert_id,
           inverse_of: :assigned_expert,
           dependent: :nullify
  has_many :messages,
           foreign_key: :sender_id,
           inverse_of: :sender,
           dependent: :destroy
  has_one :expert_profile,
          inverse_of: :user,
          dependent: :destroy
  has_many :expert_assignments,
           foreign_key: :expert_id,
           inverse_of: :expert,
           dependent: :destroy

  before_validation :normalize_username
  before_create :set_last_active_at

  validates :username, presence: true,
                       uniqueness: { case_sensitive: false }
  private

  def normalize_username
    return if username.blank?

    self.username = username.to_s.strip.downcase
  end

  def set_last_active_at
    self.last_active_at ||= Time.current
  end
end
