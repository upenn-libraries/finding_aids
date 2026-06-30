class CreateCollectionGuides < ActiveRecord::Migration[8.1]
  def change
    create_table :collection_guides do |t|
      t.string :title, null: false
      t.string :repository, null: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :collection_guides, :position
    add_index :collection_guides, :active
  end
end
