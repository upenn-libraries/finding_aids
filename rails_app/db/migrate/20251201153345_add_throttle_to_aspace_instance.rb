# frozen_string_literal: true

# Add optional throttle value to ASpace instance
class AddThrottleToASpaceInstance < ActiveRecord::Migration[7.2]
  def change
    change_table :aspace_instances, bulk: true do |t|
      t.float :throttle
    end
  end
end
