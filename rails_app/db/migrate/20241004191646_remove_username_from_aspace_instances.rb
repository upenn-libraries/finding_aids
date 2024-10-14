# frozen_string_literal: true

class RemoveUsernameFromASpaceInstances < ActiveRecord::Migration[7.0]
  def change
    remove_column :aspace_instances, :username, :string
  end
end
