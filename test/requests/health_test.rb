require "test_helper"

class HealthTest < ActionDispatch::IntegrationTest
  test "health endpoint returns status ok" do
    get "/health"

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal "ok", body["status"]
    assert body["timestamp"].present?
  end
end

