class ExpertAssignment < ApplicationRecord
  STATUSES = {
    active: "active",
    resolved: "resolved"
  }.freeze

  belongs_to :conversation, inverse_of: :expert_assignments
  belongs_to :expert, class_name: "User", inverse_of: :expert_assignments

  enum :status, STATUSES, validate: false, default: :active

  validates :status, inclusion: { in: STATUSES.values, message: "is not a valid status" }
  validates :assigned_at, presence: true

  before_validation :set_assigned_at, on: :create

  private

  def set_assigned_at
    self.assigned_at ||= Time.current
  end
end
