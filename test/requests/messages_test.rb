require "test_helper"

class MessagesTest < ActionDispatch::IntegrationTest
  fixtures :users, :conversations, :messages

  setup do
    @initiator = users(:one)
    @expert = users(:two)
    @conversation = conversations(:one)
    @initiator_token = JwtService.encode({ user_id: @initiator.id })
    @expert_token = JwtService.encode({ user_id: @expert.id })
  end

  test "requires authentication" do
    get "/conversations/#{@conversation.id}/messages"
    assert_response :unauthorized

    post "/messages", params: { conversationId: @conversation.id, content: "Hello" }, as: :json
    assert_response :unauthorized
  end

  test "lists messages for conversation" do
    get "/conversations/#{@conversation.id}/messages", headers: auth_header(@initiator)
    assert_response :ok

    body = JSON.parse(response.body)
    assert_equal 2, body.size
    contents = body.map { |entry| entry["content"] }
    assert_equal ["How do I deploy Rails?", "Let me help you with that."].sort, contents.sort
  end

  test "prevents non participants from viewing messages" do
    outsider = User.create!(username: "outsider", password: "password123", password_confirmation: "password123")
    header = { "Authorization" => "Bearer #{JwtService.encode({ user_id: outsider.id })}" }

    get "/conversations/#{@conversation.id}/messages", headers: header
    assert_response :forbidden
  end

  test "creates message as initiator" do
    assert_difference("Message.count", 1) do
      post "/messages", params: {
        conversationId: @conversation.id,
        content: "New update from initiator"
      }, headers: auth_header(@initiator), as: :json
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "New update from initiator", body["content"]
    assert_equal @initiator.id.to_s, body["senderId"]
    assert_equal "initiator", body["senderRole"]

    @conversation.reload
    assert @conversation.last_message_at.present?
  end

  test "prevents users who are not participants from creating messages" do
    outsider = User.create!(username: "outsider2", password: "password123", password_confirmation: "password123")
    header = { "Authorization" => "Bearer #{JwtService.encode({ user_id: outsider.id })}" }

    assert_no_difference("Message.count") do
      post "/messages", params: { conversationId: @conversation.id, content: "Should not work" }, headers: header, as: :json
    end

    assert_response :forbidden
  end

  test "returns not found when conversation does not exist" do
    assert_no_difference("Message.count") do
      post "/messages", params: { conversationId: 0, content: "Hello" }, headers: auth_header(@initiator), as: :json
    end

    assert_response :not_found
  end

  private

  def auth_header(user)
    token = user == @initiator ? @initiator_token : @expert_token
    { "Authorization" => "Bearer #{token}" }
  end
end

