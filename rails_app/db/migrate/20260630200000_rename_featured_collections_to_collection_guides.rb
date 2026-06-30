# frozen_string_literal: true

class RenameFeaturedCollectionsToCollectionGuides < ActiveRecord::Migration[8.0]
  def change
    rename_table :featured_collections, :collection_guides
  end
end
