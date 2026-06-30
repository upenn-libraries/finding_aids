# frozen_string_literal: true

class RemovePositionFromCollectionGuides < ActiveRecord::Migration[8.0]
  def change
    remove_index :collection_guides, :position, if_exists: true
    remove_column :collection_guides, :position, :integer, null: false, default: 0, if_exists: true
  end
end
