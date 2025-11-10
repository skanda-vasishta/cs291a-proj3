require "test_helper"

class ConversationsTest < ActionDispatch::IntegrationTest
  fixtures :users, :conversations, :messages

  setup do
    @initiator = users(:one)
    @expert = users(:two)
    @token_for_initiator = JwtService.encode({ user_id: @initiator.id })
    @token_for_expert = JwtService.encode({ user_id: @expert.id })
  end

  test "requires authentication" do
    get "/conversations"
    assert_response :unauthorized

    get "/conversations/#{conversations(:one).id}"
    assert_response :unauthorized
  end

  test "lists conversations where user is initiator or assigned expert" do
    get "/conversations", headers: auth_header(@initiator)
    assert_response :ok
    body = JSON.parse(response.body)

    assert_equal 3, body.length
    ids = body.map { |c| c["id"] }
    assert_includes ids, conversations(:one).id.to_s
    assert_includes ids, conversations(:waiting_unassigned).id.to_s
    assert_includes ids, conversations(:assigned_to_one).id.to_s
  end

  test "lists conversations for expert role" do
    get "/conversations", headers: auth_header(@expert)
    assert_response :ok

    body = JSON.parse(response.body)
    ids = body.map { |c| c["id"] }
    assert_includes ids, conversations(:one).id.to_s
    assert_includes ids, conversations(:assigned_to_one).id.to_s
  end

  test "shows conversation if participant" do
    conversation = conversations(:one)

    get "/conversations/#{conversation.id}", headers: auth_header(@initiator)
    assert_response :ok

    body = JSON.parse(response.body)
    assert_equal conversation.id.to_s, body["id"]
    assert_equal conversation.title, body["title"]
    assert_equal "active", body["status"]
    assert_equal conversation.initiator_id.to_s, body["questionerId"]
    assert_equal conversation.initiator.username, body["questionerUsername"]
    assert_equal conversation.assigned_expert_id.to_s, body["assignedExpertId"]
    assert_equal conversation.assigned_expert.username, body["assignedExpertUsername"]
    assert_equal body["unreadCount"], 1
  end

  test "prevents viewing conversation if not involved" do
    other_user = User.create!(username: "outsider", password: "password123", password_confirmation: "password123")
    token = JwtService.encode({ user_id: other_user.id })

    get "/conversations/#{conversations(:one).id}", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :not_found
  end

  test "creates conversation" do
    assert_difference("Conversation.count", 1) do
      post "/conversations", params: {
        conversation: { title: "Need help with caching" }
      }, headers: auth_header(@initiator), as: :json
    end

    assert_response :created

    body = JSON.parse(response.body)
    assert_equal "Need help with caching", body["title"]
    assert_equal @initiator.id.to_s, body["questionerId"]
    assert_nil body["assignedExpertId"]
    assert_equal "waiting", body["status"]
  end

  test "fails to create conversation without title" do
    assert_no_difference("Conversation.count") do
      post "/conversations", params: {
        conversation: { title: "" }
      }, headers: auth_header(@initiator), as: :json
    end

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_includes body["errors"], "Title can't be blank"
  end

  private

  def auth_header(user)
    token = user == @initiator ? @token_for_initiator : @token_for_expert
    { "Authorization" => "Bearer #{token}" }
  end
end

