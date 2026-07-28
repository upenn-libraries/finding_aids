# frozen_string_literal: true

module Ead
  module Extraction
    module Inventory
      # Provides desired display data for Entry objects
      class EntryPresenter
        NO_TITLE = '(No Title)'

        attr_reader :entry

        # @param entry [Ead::Extraction::Inventory::Entry]
        def initialize(entry)
          @entry = entry
        end

        # @return [ActiveSupport::SafeBuffer, String]
        def heading
          title(title: entry.title_html, origination: entry.origination, date: date,
                extent: extent_integer)
        end

        # @return [ActiveSupport::SafeBuffer, String]
        def condensed_heading
          title(title: entry.title_html, origination: entry.origination)
        end

        # @return [String]
        def date
          non_bulk_date = entry.non_bulk_date
          bulk_date = entry.bulk_date

          return if non_bulk_date.blank? && bulk_date.blank?

          bulk_date = "(#{bulk_date})" if bulk_date

          [non_bulk_date, bulk_date].compact_blank.join(' ')
        end

        # @return [String]
        def extent_integer
          extent = entry.extent
          extent ? " #{extent.gsub(/(\d+)\.0/, '\1')}." : ''
        end

        # @return [String]
        def join_containers
          entry.containers.map(&:to_s).join(', ')
        end

        # @param title [ActiveSupport::SafeBuffer, String] sanitized title
        # @param origination [String, nil]
        # @param date [String, nil]
        # @param extent [String, nil]
        # @param unitid [String, nil]
        # @return [ActiveSupport::SafeBuffer, String]
        def title(title:, origination: nil, date: nil, extent: nil, unitid: nil)
          title = [unitid, origination, title].compact_blank.join('. ')
          title = [title, date].compact_blank.join(', ')
          title.concat extent if extent.present?

          ActiveSupport::SafeBuffer.new(title.presence || NO_TITLE)
        end
      end
    end
  end
end
