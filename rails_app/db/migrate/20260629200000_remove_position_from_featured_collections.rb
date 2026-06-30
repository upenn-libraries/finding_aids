# frozen_string_literal: true

class RemovePositionFromFeaturedCollections < ActiveRecord::Migration[8.0]
  def change
    remove_index :featured_collections, :position, if_exists: true
    remove_column :featured_collections, :position, :integer, null: false, default: 0, if_exists: true
  end
end
