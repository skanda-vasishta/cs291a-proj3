require "test_helper"

class ExpertAssignmentTest < ActiveSupport::TestCase
  fixtures :users, :conversations, :expert_assignments

  test "defaults status to active and sets assigned_at" do
    assignment = ExpertAssignment.create!(
      conversation: conversations(:waiting_unassigned),
      expert: users(:two)
    )

    assert_equal "active", assignment.status
    assert assignment.assigned_at.present?
  end

  test "requires assigned_at" do
    assignment = expert_assignments(:one)
    assignment.assigned_at = nil

    assert_not assignment.valid?
    assert_includes assignment.errors[:assigned_at], "can't be blank"
  end

  test "validates status values" do
    assignment = ExpertAssignment.new(
      conversation: conversations(:one),
      expert: users(:two),
      assigned_at: Time.current
    )

    assert_raises ArgumentError do
      assignment.status = "unknown"
    end
  end
end
