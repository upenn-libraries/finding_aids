# frozen_string_literal: true

module Ead
  module Extraction
    module Inventory
      # Provides desired display data for Entry objects
      class EntryPresenter
        NO_TITLE = '(No Title)'
        class << self
          # @return [ActiveSupport::SafeBuffer, String]
          def heading(entry)
            title(title: entry.title_html, origination: entry.origination, date: date(entry),
                  extent: extent_integer(entry))
          end

          # @return [ActiveSupport::SafeBuffer, String]
          def condensed_heading(entry)
            title(title: entry.title_html, origination: entry.origination)
          end

          # @param entry [Ead::Extraction::Inventory::Entry]
          # @return [String]
          def date(entry)
            non_bulk_date = entry.non_bulk_date
            bulk_date = entry.bulk_date

            return if non_bulk_date.blank? && bulk_date.blank?

            bulk_date = "(#{bulk_date})" if bulk_date

            [non_bulk_date, bulk_date].compact_blank.join(' ')
          end

          # @param entry [Ead::Extraction::Inventory::Entry]
          # @return [String]
          def extent_integer(entry)
            extent = entry.extent
            extent ? " #{extent.gsub(/(\d+)\.0/, '\1')}." : ''
          end

          # @param entry [Ead::Extraction::Inventory::Entry]
          # @return [String]
          def join_containers(entry)
            entry.containers.map(&:to_s).join(', ')
          end

          # @param title [ActiveSupport::SafeBuffer, String]
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
end
