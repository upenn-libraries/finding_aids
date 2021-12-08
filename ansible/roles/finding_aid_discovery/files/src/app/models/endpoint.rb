# Represent a partner's endpoint from which we will harvest records
class Endpoint < ApplicationRecord
  TYPES = %w[index]

  validates :slug, presence: true, uniqueness: true
  validates :type, presence: true, inclusion: TYPES
  validates :url, presence: true

  # maybe?
  scope :index_type, -> { where('harvest_config @> ?', { type: 'index' }.to_json ) }

  # @return [String]
  def url
    harvest_config.dig 'url'
  end

  # @return [String]
  def type
    harvest_config.dig 'type'
  end

  # @return [Array]
  def last_harvest_errors
    last_harvest_results.dig 'errors'
  end

  # @return [TrueClass, FalseClass]
  def last_harvest_successful?
    last_harvest_errors.empty?
  end

  # @return [TrueClass, FalseClass]
  def last_harvest_failed?
    last_harvest_errors.any?
  end

  # @return [Object]
  def extractor
    @extractor ||= extractor_class.new(self)
  end

  def extractor_class
    "#{type.titlecase}Extractor".constantize
  end

  def parser
    @parser ||= parser_class.new(self)
  end

  def parser_class
    if harvest_config.dig('parser', nil).present?
      "#{harvest_config['parser']}Parser".constantize
    else
      EadParser
    end
  end
end
