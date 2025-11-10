class CreateExpertProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :expert_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.text :bio
      t.json :knowledge_base_links

      t.timestamps
    end

    add_index :expert_profiles, :user_id, unique: true unless index_exists?(:expert_profiles, :user_id)
  end
end
