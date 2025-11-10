require "test_helper"

class ApiUpdatesTest < ActionDispatch::IntegrationTest
  fixtures :users, :conversations, :messages

  setup do
    @initiator = users(:one)
    @expert = users(:two)
    @initiator_token = JwtService.encode({ user_id: @initiator.id })
    @expert_token = JwtService.encode({ user_id: @expert.id })
  end

  test "conversations updates require auth" do
    get "/api/conversations/updates", params: { userId: @initiator.id }
    assert_response :unauthorized
  end

  test "conversations updates return conversations since timestamp" do
    travel_to Time.utc(2025, 11, 10, 10, 0, 0) do
      fresh = conversations(:one)
      stale = conversations(:waiting_unassigned)

      fresh.touch
      stale.update_columns(updated_at: 2.hours.ago)

      get "/api/conversations/updates",
          params: { userId: @initiator.id, since: 1.minute.ago.iso8601 },
          headers: initiator_header

      assert_response :ok
      body = JSON.parse(response.body)
      ids = body.map { |conv| conv["id"] }
      assert_includes ids, fresh.id.to_s
      refute_includes ids, stale.id.to_s
    end
  end

  test "messages updates filter by timestamp" do
    travel_to Time.utc(2025, 11, 10, 11, 0, 0) do
      conversation = conversations(:one)
      new_message = Message.create!(
        conversation:,
        sender: @initiator,
        sender_role: :initiator,
        content: "New message from initiator"
      )

      get "/api/messages/updates",
          params: { userId: @initiator.id, since: 1.minute.ago.iso8601 },
          headers: initiator_header

      assert_response :ok
      body = JSON.parse(response.body)
      ids = body.map { |msg| msg["id"] }
      assert_includes ids, new_message.id.to_s
    end
  end

  test "expert queue updates require matching expert id" do
    get "/api/expert-queue/updates", params: { expertId: @expert.id }, headers: initiator_header
    assert_response :unauthorized
  end

  test "expert queue updates return waiting and assigned updates" do
    travel_to Time.utc(2025, 11, 10, 12, 0, 0) do
      waiting = conversations(:waiting_unassigned)
      waiting.touch
      assigned = conversations(:one)
      assigned.touch

      get "/api/expert-queue/updates",
          params: { expertId: @expert.id, since: 1.minute.ago.iso8601 },
          headers: expert_header

      assert_response :ok
      body = JSON.parse(response.body).first

      waiting_ids = body["waitingConversations"].map { |conv| conv["id"] }
      assigned_ids = body["assignedConversations"].map { |conv| conv["id"] }

      assert_includes waiting_ids, waiting.id.to_s
      assert_includes assigned_ids, assigned.id.to_s
    end
  end

  private

  def initiator_header
    { "Authorization" => "Bearer #{@initiator_token}" }
  end

  def expert_header
    { "Authorization" => "Bearer #{@expert_token}" }
  end
end

