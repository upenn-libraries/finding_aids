# frozen_string_literal: true

# Represent a partner's endpoint from which we will harvest records
class Endpoint < ApplicationRecord
  include Synchronizable

  WEBPAGE_TYPE = 'webpage'
  ASPACE_TYPE = 'aspace'
  SOURCE_TYPES = [WEBPAGE_TYPE, ASPACE_TYPE].freeze

  validates :slug, presence: true, uniqueness: true, format: { with: /\A[A-Za-z_]+\z/ }
  validates :source_type, presence: true, inclusion: SOURCE_TYPES
  validates :webpage_url, presence: true, if: :webpage_type?
  validates :webpage_url, absence: true, if: :aspace_type?
  validates :aspace_repo_id, :aspace_instance, presence: true, if: :aspace_type?
  validates :aspace_repo_id, :aspace_instance, absence: true, if: :webpage_type?
  validates :active, inclusion: [true, false]

  belongs_to :aspace_instance, optional: true

  scope :is_active, -> { where(active: true) }

  def aspace_type?
    source_type == ASPACE_TYPE
  end

  def webpage_type?
    source_type == WEBPAGE_TYPE
  end

  def last_harvest
    @last_harvest ||= LastHarvest.new(last_harvest_results)
  end

  # URL to display in UI and mailers.
  def display_url
    if webpage_type?
      webpage_url
    else
      aspace_instance&.base_url
    end
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
      return nil if results.to_h.blank?
      return FAILED if errors&.any?
      return PARTIAL if problem_files.any?

      COMPLETE
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

  # Return Class for parsing xml_urls for this Endpoint
  # @note This function was originally written to extract the "parser" value from the harvest_config with the idea
  #   that we may need different parser classes for different records. The method will stay in place in case we
  #   need this functionality down the road.
  def parser_class
    EadParser
  end

  def reload
    @last_harvest = nil # Resetting last_harvest so the object is re-instantiated with fresh data.
    super
  end
end
