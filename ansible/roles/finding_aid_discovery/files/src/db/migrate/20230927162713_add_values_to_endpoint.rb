# frozen_string_literal: true

class AddValuesToEndpoint < ActiveRecord::Migration[7.0]
  def change
    add_column :endpoints, :type, :string
    add_column :endpoints, :url, :text
    add_column :endpoints, :aspace_id, :integer
  end
end
