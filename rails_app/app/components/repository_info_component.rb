# frozen_string_literal: true

# Renders message with repository information
class RepositoryInfoComponent < ViewComponent::Base
  renders_one :address, -> { content_tag(:span, document.repository_address, class: 'repository-location') }

  attr_reader :document, :contact_links

  # @param document [SolrDocument]
  def initialize(document:)
    @document = document
  end

  # @return [String]
  def message
    t('messages.location_html', repository: document.repository, email_link: contact_links.contact_us_email_link)
  end

  # @return [String]
  def location_classes
    classes = ['repository-info']
    if document.penn_item?
      classes << 'upenn'
    elsif document.princeton_item?
      classes << 'princeton'
    end
    classes.join(' ')
  end

  def before_render
    @contact_links = RepositoryContactLinks.new(document: @document, request_url: request.original_url)
  end
end
