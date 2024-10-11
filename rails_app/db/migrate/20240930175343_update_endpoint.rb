# frozen_string_literal: true

class UpdateEndpoint < ActiveRecord::Migration[7.0]
  def change
    rename_column :endpoints, :url, :webpage_url
    rename_column :endpoints, :aspace_id, :aspace_repo_id

    remove_column :endpoints, :harvest_config, :jsonb

    change_column_null :endpoints, :slug, false
    change_column_null :endpoints, :source_type, false
  end
end
