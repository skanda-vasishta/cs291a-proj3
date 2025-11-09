require "test_helper"

class UsersRegistrationTest < ActionDispatch::IntegrationTest
  test "registers a new user" do
    payload = {
      user: {
        username: "newuser",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    assert_difference("User.count", 1) do
      post "/auth/register", params: payload, as: :json
    end

    assert_response :created

    body = JSON.parse(response.body)
    user_data = body["user"]

    assert_equal "newuser", user_data["username"]
    assert user_data["id"].present?
    assert user_data["created_at"].present?
    assert user_data["last_active_at"].present?
    assert body["token"].present?
  end

  test "returns errors when registration is invalid" do
    payload = {
      user: {
        username: "",
        password: "short",
        password_confirmation: "mismatch"
      }
    }

    assert_no_difference("User.count") do
      post "/auth/register", params: payload, as: :json
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)
    errors = body["errors"]

    assert_includes errors, "Username can't be blank"
    assert_includes errors, "Password is too short (minimum is 8 characters)"
    assert_includes errors, "Password confirmation doesn't match Password"
  end
end

