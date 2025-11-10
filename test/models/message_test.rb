require "test_helper"

class MessageTest < ActiveSupport::TestCase
  fixtures :users, :conversations

  test "is valid with required attributes" do
    message = Message.new(
      conversation: conversations(:one),
      sender: users(:one),
      sender_role: :initiator,
      content: "Hello!"
    )

    assert message.valid?
  end

  test "requires content" do
    message = Message.new(
      conversation: conversations(:one),
      sender: users(:one),
      sender_role: :initiator
    )

    assert_not message.valid?
    assert_includes message.errors[:content], "can't be blank"
  end

  test "requires valid sender role" do
    message = Message.new(
      conversation: conversations(:one),
      sender: users(:two),
      content: "Invalid role"
    )

    assert_raises ArgumentError do
      message.sender_role = "moderator"
    end
  end

  test "is_read defaults to false on create" do
    message = Message.create!(
      conversation: conversations(:one),
      sender: users(:two),
      sender_role: :expert,
      content: "Responding to the question"
    )

    assert_not message.reload.is_read
  end
end
require "test_helper"

class MessageTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
