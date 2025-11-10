require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  fixtures :users, :conversations

  test "is valid with required attributes" do
    conversation = Conversation.new(
      title: "Need help with Docker",
      initiator: users(:one),
      assigned_expert: users(:two)
    )

    assert conversation.valid?
    assert_equal "waiting", conversation.status
  end

  test "allows missing assigned expert" do
    conversation = Conversation.new(
      title: "Waiting for expert",
      initiator: users(:one)
    )

    assert conversation.valid?
  end

  test "requires title" do
    conversation = Conversation.new(
      initiator: users(:one),
      status: :waiting
    )

    assert_not conversation.valid?
    assert_includes conversation.errors[:title], "can't be blank"
  end

  test "requires valid status" do
    conversation = Conversation.new(
      title: "Invalid",
      initiator: users(:one)
    )

    assert_raises ArgumentError do
      conversation.status = "unknown"
    end
  end
end
require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
