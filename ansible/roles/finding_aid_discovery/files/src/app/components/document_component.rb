# frozen_string_literal: true

# custom methods for our DocumentComponent
class DocumentComponent < Blacklight::DocumentComponent
  # Content for the collection inventory tab
  renders_one :collection_inventory

  # Slot for collapsable metadata sections
  renders_many :collapsable_metadata_sections, 'CollapsableMetadataSection'

  def location_message
    content_tag :p, class: 'repository-info' do
      t('messages.location_html',
        repository: @document.repository,
        contact_email: @document[:contact_emails_ssm].first)
    end
  end

  def access_clarification_message
    content_tag :p, class: 'access-clarification' do
      content_tag :i do
        t('messages.access_clarification_html', repository: @document.repository)
      end
    end
  end

  def correction_email_link(page_url)
    mail_to @document.correction_email, 'Suggest a correction',
            subject: "Correction to #{@document.title} finding aid",
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
      render CollapsableSectionComponent.new(id: title.parameterize, open:) do |section|
        section.title { title }
        section.body { content }
      end
    end
  end
end
