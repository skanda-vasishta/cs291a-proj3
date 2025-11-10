class Message < ApplicationRecord
  ROLES = {
    initiator: "initiator",
    expert: "expert"
  }.freeze

  attribute :is_read, :boolean, default: false

  belongs_to :conversation, inverse_of: :messages
  belongs_to :sender, class_name: "User", inverse_of: :messages

  enum :sender_role, ROLES, validate: false

  validates :content, presence: true
  validates :sender_role, inclusion: { in: ROLES.values, message: "is not a valid sender_role" }
end
