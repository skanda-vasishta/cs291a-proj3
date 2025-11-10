require "test_helper"

class ExpertProfileTest < ActiveSupport::TestCase
  fixtures :users, :expert_profiles

  test "is valid with default attributes" do
    profile = expert_profiles(:one)
    assert profile.valid?
    assert_equal 2, profile.knowledge_base_links.size
  end

  test "enforces unique user" do
    duplicate = ExpertProfile.new(user: profile_user, bio: "Another bio")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "validates links are strings" do
    profile = ExpertProfile.new(user: users(:one), knowledge_base_links: ["https://example.com"])
    assert profile.valid?

    profile.knowledge_base_links = ["valid", 123]
    assert_not profile.valid?
    assert_includes profile.errors[:knowledge_base_links], "must be an array of strings"
  end

  private

  def profile_user
    users(:two)
  end
end
