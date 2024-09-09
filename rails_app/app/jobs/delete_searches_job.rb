# frozen_string_literal: true

# Job to clear out searches table in order to prevent the database from ballooning.
class DeleteSearchesJob < ApplicationJob
  queue_as :default

  # Deletes all the searches that are older than seven days. This job should
  # be scheduled to run regularly.
  def perform
    Search.where(created_at: Date.new..7.days.ago)
          .find_in_batches(batch_size: 100) { |batch| batch.each(&:destroy) }
  end
end
