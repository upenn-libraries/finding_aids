# frozen_string_literal: true

class CreateFeaturedCollections < ActiveRecord::Migration[8.1]
  def change
    create_table :featured_collections do |t|
      t.string :record_id, null: false
      t.string :title
      t.string :repository
    end
  end
end
