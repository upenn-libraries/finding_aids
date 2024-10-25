# frozen_string_literal: true

class AddActiveToEndpoints < ActiveRecord::Migration[7.2]
  def change
    add_column :endpoints, :active, :boolean, default: true, null: false
  end
end
