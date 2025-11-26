# frozen_string_literal: true

# Builds mail_to links to contact the repository
class RepositoryContactLinks < ViewComponent::Base
  include ActionView::Helpers::UrlHelper

  # @param  document [SolrDocument]
  # @param request_url [String]
  # @return [ActiveSupport::SafeBuffer]
  def self.contact_us(document:, request_url:)
    new(document: document, request_url: request_url).contact_us_email_link
  end

  # @param  document [SolrDocument]
  # @param request_url [String]
  # @return [ActiveSupport::SafeBuffer]
  def self.correction(document:, request_url:)
    new(document: document, request_url: request_url).correction_email_link
  end

  attr_reader :document, :request_url

  # @param  document [SolrDocument]
  # @param request_url [String]
  def initialize(document:, request_url: nil)
    @document = document
    @request_url = request_url
  end

  # @return [ActiveSupport::SafeBuffer]
  def contact_us_email_link
    mail_to document.contact_email, I18n.t('document.links.contact_us'),
            subject: "Question about #{document.title} finding aid",
            body: "\n\nFrom: #{request_url}"
  end

  def correction_email_link
    mail_to document.contact_email, I18n.t('document.links.submit_correction'),
            subject: "Correction to #{document.title} finding aid",
            body: "\n\nFrom: #{request_url}"
  end
end
