class Conversation < ApplicationRecord
  STATUSES = {
    waiting: "waiting",
    active: "active",
    resolved: "resolved"
  }.freeze

  belongs_to :initiator, class_name: "User", inverse_of: :initiated_conversations
  belongs_to :assigned_expert, class_name: "User", optional: true, inverse_of: :assigned_conversations

  has_many :messages, dependent: :destroy
  has_many :expert_assignments, dependent: :destroy

  enum :status, STATUSES, validate: false, default: :waiting

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES.values, message: "is not a valid status" }
end
