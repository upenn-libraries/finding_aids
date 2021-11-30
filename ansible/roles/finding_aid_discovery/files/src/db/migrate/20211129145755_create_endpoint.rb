class CreateEndpoint < ActiveRecord::Migration[6.1]
  def change
    create_table :endpoints do |t|
      t.string :slug
      t.string :public_contacts, array: true
      t.string :tech_contacts, array: true
      t.jsonb :harvest_config, null: false, default: '{}'
      t.jsonb :last_harvest_results, default: '{}'
      t.timestamps
    end
  end
end
