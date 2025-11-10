require "test_helper"

class ExpertEndpointsTest < ActionDispatch::IntegrationTest
  fixtures :users, :conversations, :messages, :expert_profiles, :expert_assignments

  setup do
    @expert = users(:two)
    @initiator = users(:one)
    @expert_token = JwtService.encode({ user_id: @expert.id })
    @initiator_token = JwtService.encode({ user_id: @initiator.id })
  end

  test "requires auth for expert endpoints" do
    get "/expert/profile"
    assert_response :unauthorized

    get "/expert/queue"
    assert_response :unauthorized
  end

  test "fetches expert profile" do
    get "/expert/profile", headers: expert_header
    assert_response :ok

    body = JSON.parse(response.body)
    assert_equal @expert.id.to_s, body["userId"]
    assert_equal "Experienced Rails developer with mentoring experience.", body["bio"]
  end

  test "updates expert profile" do
    put "/expert/profile",
        params: {
          expert_profile: {
            bio: "Updated bio",
            knowledge_base_links: ["https://example.com"]
          }
        },
        headers: expert_header,
        as: :json

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal "Updated bio", body["bio"]
    assert_equal ["https://example.com"], body["knowledgeBaseLinks"]
  end

  test "shows expert queue" do
    get "/expert/queue", headers: expert_header
    assert_response :ok

    body = JSON.parse(response.body)
    waiting_ids = body["waitingConversations"].map { |conv| conv["id"] }
    assigned_ids = body["assignedConversations"].map { |conv| conv["id"] }

    assert_includes waiting_ids, conversations(:waiting_unassigned).id.to_s
    assert_includes assigned_ids, conversations(:one).id.to_s
  end

  test "claims a conversation" do
    waiting = conversations(:waiting_unassigned)

    post "/expert/conversations/#{waiting.id}/claim", headers: expert_header
    assert_response :ok

    waiting.reload
    assert_equal @expert.id, waiting.assigned_expert_id
    assert_equal "active", waiting.status
    assert_equal 1, ExpertAssignment.where(conversation: waiting, expert: @expert).count
  end

  test "unclaims a conversation" do
    conversation = conversations(:one)

    post "/expert/conversations/#{conversation.id}/unclaim", headers: expert_header
    assert_response :ok

    conversation.reload
    assert_nil conversation.assigned_expert_id
    assert_equal "waiting", conversation.status

    assignment = ExpertAssignment.where(conversation:, expert: @expert).order(created_at: :desc).first
    assert_equal "resolved", assignment.status
    assert assignment.resolved_at.present?
  end

  test "lists assignment history" do
    get "/expert/assignments/history", headers: expert_header
    assert_response :ok

    body = JSON.parse(response.body)
    assert_equal 1, body.length
    assert_equal expert_assignments(:one).conversation_id.to_s, body.first["conversationId"]
  end

  private

  def expert_header
    { "Authorization" => "Bearer #{@expert_token}" }
  end
end

