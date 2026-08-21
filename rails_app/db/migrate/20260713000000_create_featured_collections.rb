# frozen_string_literal: true

class CreateFeaturedCollections < ActiveRecord::Migration[8.1]
  def change
    create_table :featured_collections do |t|
      t.string :record_id, null: false, unique: true
      t.string :title
      t.string :repository
      t.timestamps
    end
  end
end
