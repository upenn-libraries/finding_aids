# Represent a partner's endpoint from which we will harvest records
class Endpoint < ApplicationRecord
  TYPES = %w[index]
  FAILURE_STATUS = 'failed'
  SUCCESS_STATUS = 'success'

  validates :slug, presence: true, uniqueness: true
  validates :type, presence: true, inclusion: TYPES
  validates :url, presence: true

  # maybe?
  scope :index_type, -> { where('harvest_config @> ?', { type: 'index' }.to_json ) }
  scope :last_failed, -> { where('last_harvest_results @> ?', { status: FAILURE_STATUS }.to_json) }

  # @return [String]
  def url
    harvest_config.dig 'url'
  end

  # @return [String]
  def type
    harvest_config.dig 'type'
  end

  # @return [String]
  def last_harvest_status
    last_harvest_results.dig 'status'
  end

  # @return [TrueClass, FalseClass]
  def last_harvest_successful?
    last_harvest_status == SUCCESS_STATUS
  end

  # @return [TrueClass, FalseClass]
  def last_harvest_failed?
    last_harvest_status == FAILURE_STATUS
  end
end
