require "test_helper"

class UserTest < ActiveSupport::TestCase
  fixtures :users

  test "is valid with username and password" do
    user = User.new(username: "charlie", password: "password123", password_confirmation: "password123")

    assert user.valid?
  end

  test "requires username" do
    user = User.new(password: "password123", password_confirmation: "password123")

    assert_not user.valid?
    assert_includes user.errors[:username], "can't be blank"
  end

  test "requires unique username regardless of case" do
    existing = users(:one)
    user = User.new(username: existing.username.upcase, password: "password123", password_confirmation: "password123")

    assert_not user.valid?
    assert_includes user.errors[:username], "has already been taken"
  end

  test "normalizes username before validation" do
    user = User.create!(username: "  MixedCaseUser  ", password: "password123", password_confirmation: "password123")

    assert_equal "mixedcaseuser", user.username
  end

  test "sets last_active_at on create when not provided" do
    user = User.create!(username: "eve", password: "password123", password_confirmation: "password123")

    assert user.last_active_at.present?
  end
end
