# frozen_string_literal: true

# custom methods for our DocumentComponent
class DocumentComponent < Blacklight::DocumentComponent
  # Slot for the collection inventory section
  renders_one :collection_inventory

  # Slots for collapsable metadata sections
  renders_many :collapsable_metadata_sections, 'CollapsableMetadataSection'

  # @param [TrueClass, FalseClass] with_address
  # @param [String] url
  def location_message(url:, with_address: false)
    inner_html = t('messages.location_html', repository: @document.repository,
                                             email_link: contact_us_email_link(url))
    inner_html += content_tag(:span, @document.repository_address, class: 'repository-location') if with_address

    content_tag :p, inner_html, class: location_classes
  end

  # @return [Array<String (frozen)>]
  def location_classes
    classes = ['repository-info']
    if @document.penn_item?
      classes << 'upenn'
    elsif @document.princeton_item?
      classes << 'princeton'
    end
    classes
  end

  def access_clarification_message
    content_tag :p, class: 'access-clarification' do
      content_tag :i do
        t('messages.access_clarification_html', repository: @document.repository)
      end
    end
  end

  # @param [String] page_url
  # @return [ActiveSupport::SafeBuffer]
  def correction_email_link(page_url)
    mail_to @document.contact_email, t('document.links.submit_correction'),
            subject: "Correction to #{@document.title} finding aid",
            body: "\n\nFrom: #{page_url}"
  end

  # @param [String] page_url
  # @return [ActiveSupport::SafeBuffer]
  def contact_us_email_link(page_url)
    mail_to @document.contact_email, t('document.links.contact_us'),
            subject: "Question about #{@document.title} finding aid",
            body: "\n\nFrom: #{page_url}"
  end

  # Component for a collapsable metadata section
  class CollapsableMetadataSection < ViewComponent::Base
    attr_reader :title, :open

    def initialize(title:, open: false)
      @title = title
      @open = open
    end

    def render?
      content.present?
    end

    def call
      render CollapsableSectionComponent.new(id: title.parameterize, open: open) do |section|
        section.title { title }
        section.body { content }
      end
    end
  end
end
