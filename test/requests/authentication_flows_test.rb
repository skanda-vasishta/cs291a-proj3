require "test_helper"

class AuthenticationFlowsTest < ActionDispatch::IntegrationTest
  fixtures :users

  setup do
    @user = users(:one)
    @password = "password123"
    @user.update!(password: @password, password_confirmation: @password)
  end

  test "logs in with valid credentials" do
    post "/auth/login", params: {
      user: {
        username: @user.username,
        password: @password
      }
    }, as: :json

    assert_response :ok
    body = JSON.parse(response.body)

    assert_equal @user.username, body["user"]["username"]
    assert body["token"].present?
    assert cookies["_session_id"].present?, "login should set session cookie"
  end

  test "rejects invalid login" do
    post "/auth/login", params: {
      user: {
        username: @user.username,
        password: "wrong"
      }
    }, as: :json

    assert_response :unauthorized
    body = JSON.parse(response.body)

    assert_equal "Invalid username or password", body["error"]
  end

  test "refresh requires session" do
    post "/auth/refresh", as: :json

    assert_response :unauthorized
    assert_equal({ "error" => "No session found" }, JSON.parse(response.body))
  end

  test "refresh returns new token with session" do
    login_as_user

    assert_changes -> { @user.reload.last_active_at } do
      post "/auth/refresh", as: :json
    end

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal @user.username, body["user"]["username"]
    assert body["token"].present?
  end

  test "logout clears session" do
    login_as_user

    post "/auth/logout", as: :json

    assert_response :ok
    assert_equal({ "message" => "Logged out successfully" }, JSON.parse(response.body))

    post "/auth/refresh", as: :json
    assert_response :unauthorized
  end

  test "me returns current user when session exists" do
    login_as_user

    get "/auth/me", as: :json

    assert_response :ok
    assert_equal @user.username, JSON.parse(response.body)["username"]
  end

  test "me returns error when no session" do
    get "/auth/me", as: :json

    assert_response :unauthorized
    assert_equal({ "error" => "No session found" }, JSON.parse(response.body))
  end

  private

  def login_as_user
    post "/auth/login", params: {
      user: {
        username: @user.username,
        password: @password
      }
    }, as: :json

    assert_response :ok
  end
end

