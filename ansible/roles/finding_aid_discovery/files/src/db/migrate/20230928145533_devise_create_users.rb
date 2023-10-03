# frozen_string_literal: true

# create users table to use with devise and omniauth
class DeviseCreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :email, null: false, index: { unique: true }
      t.boolean :active, null: false, default: true
      t.timestamps null: false

      # omniauthable
      t.string :provider
      t.string :uid

      t.index %i[uid provider], unique: true
    end
  end
end
