# frozen_string_literal: true

# Represent a partner's endpoint from which we will harvest records
class Endpoint < ApplicationRecord
  include Synchronizable

  INDEX_TYPE = 'index'
  PENN_ASPACE_TYPE = 'penn_archives_space'
  SOURCE_TYPES = [INDEX_TYPE, PENN_ASPACE_TYPE].freeze

  validates :slug, presence: true, uniqueness: true, format: { with: /\A[A-Za-z_]+\z/ }
  validates :source_type, presence: true, inclusion: SOURCE_TYPES
  validates :url, presence: true
  validates :aspace_id, presence: true, if: :penn_aspace_type?

  scope :index_type, -> { where(source_type: 'index') }
  scope :penn_aspace_type, -> { where(source_type: 'penn_archives_space') }

  def penn_aspace_type?
    source_type == PENN_ASPACE_TYPE
  end

  def last_harvest
    @last_harvest ||= LastHarvest.new(last_harvest_results)
  end

  # Wrapper for last_harvest_results providing accessor and helper methods.
  class LastHarvest
    PARTIAL = 'partial'
    COMPLETE = 'complete'
    FAILED = 'failed'
    STATUSES = [PARTIAL, COMPLETE, FAILED].freeze

    attr_reader :results

    def initialize(results)
      @results = results
    end

    # Returns last harvest status. If no harvest was run returns nil, otherwise
    # returns one of the following statuses:
    #   FAILED: if errors were raised when trying to retrieve the endpoint url
    #   PARTIAL: if at least one error was raised when trying to harvest an individual EAD
    #   COMPLETE: if endpoint url was successfully retrieved and all EADs listed were successfully harvested
    #
    # @return [String] status of harvest run
    # @return [nil] harvest was not run
    def status
      if results.to_h.blank?
        nil
      elsif errors&.any?
        FAILED
      elsif problem_files.any?
        PARTIAL
      else
        COMPLETE
      end
    end

    STATUSES.each do |s|
      define_method "#{s}?" do
        status == s
      end
    end

    # Date and time harvest was run at.
    # @return [DateTime]
    def date
      results['date']
    end

    # Return errors that occurred when attempting to load and parse the Endpoint's URL
    # @return [Array]
    def errors
      results['errors']
    end

    # Return file information for those files referenced, downloaded and parsed from the Endpoint's URL
    # @return [Array]
    def files
      results['files']
    end

    # Return Array of file info for files unable to be harvested
    # @return [Array<Hash>]
    def problem_files
      @problem_files ||= Array.wrap(
        files&.select do |file|
          file['status'] == 'failed'
        end
      )
    end

    # Return Array of file info for files able to be harvested
    # @return [Array<Hash>]
    def success_files
      @success_files ||= Array.wrap(
        files&.select do |file|
          file['status'] == 'ok'
        end
      )
    end

    # Return Array of ids for records removed in the last harvest
    # @return [Array<Hash>]
    def removed_files
      @removed_files = Array.wrap(
        files&.select do |file|
          file['status'] == 'removed'
        end
      )
    end

    # Did the last harvest include any record removals?
    # @return [TrueClass, FalseClass]
    def removals?
      removed_files&.any?
    end
  end

  # @return [Object]
  def extractor
    @extractor ||= extractor_class.new(endpoint: self)
  end

  # Return Class for extracting XML File URLs from a source
  def extractor_class
    "#{source_type.camelize}Extractor".constantize
  end

  # @return [Object]
  def parser
    @parser ||= parser_class.new(self)
  end

  # Return Class for parsing xml_urls for this Endpoint, using
  # 'parser' value in harvest_config, if present
  def parser_class
    if harvest_config.dig('parser', nil).present?
      "#{harvest_config['parser']}Parser".constantize
    else
      EadParser
    end
  end

  def reload
    @last_harvest = nil # Resetting last_harvest so the object is re-instantiated with fresh data.
    super
  end
end
