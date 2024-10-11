# frozen_string_literal: true

class CreateASpaceInstance < ActiveRecord::Migration[7.0]
  def change
    create_table :aspace_instances do |t|
      t.string :slug, null: false, index: { unique: true }
      t.string :base_url, null: false
      t.string :username, null: false

      t.timestamps null: false
    end
  end
end
