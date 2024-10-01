# frozen_string_literal: true

class AddASpaceInstancesRefToEndpoint < ActiveRecord::Migration[7.0]
  def change
    add_reference :endpoints, :aspace_instance, index: true, foreign_key: true
  end
end
