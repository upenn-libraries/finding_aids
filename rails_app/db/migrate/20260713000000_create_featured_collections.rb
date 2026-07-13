# frozen_string_literal: true

class CreateFeaturedCollections < ActiveRecord::Migration[8.1]
  def change
    create_table :featured_collections do |t|
      t.string :title, null: false
      t.string :repository, null: false

      t.timestamps
    end
  end
end
