class CreateFeaturedCollections < ActiveRecord::Migration[8.1]
  def change
    create_table :featured_collections do |t|
      t.string :title, null: false
      t.string :repository, null: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :featured_collections, :position
    add_index :featured_collections, :active
  end
end
