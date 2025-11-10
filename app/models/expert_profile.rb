class ExpertProfile < ApplicationRecord
  belongs_to :user, inverse_of: :expert_profile

  attribute :knowledge_base_links, default: -> { [] }

  after_initialize :ensure_links_array

  validates :user_id, uniqueness: true
  validate :links_must_be_strings

  private

  def ensure_links_array
    self.knowledge_base_links = [] if knowledge_base_links.nil?
  end

  def links_must_be_strings
    return if knowledge_base_links.blank?
    return if knowledge_base_links.is_a?(Array) && knowledge_base_links.all? { |link| link.is_a?(String) }

    errors.add(:knowledge_base_links, "must be an array of strings")
  end
end
