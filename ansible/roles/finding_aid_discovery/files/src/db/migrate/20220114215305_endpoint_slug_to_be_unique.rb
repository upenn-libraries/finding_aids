class EndpointSlugToBeUnique < ActiveRecord::Migration[6.1]
  def change
    add_index :endpoints, :slug, unique: true
  end
end
