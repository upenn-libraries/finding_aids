class RenameEndpointType < ActiveRecord::Migration[7.0]
  def change
    rename_column :endpoints, :type, :source_type
  end
end
