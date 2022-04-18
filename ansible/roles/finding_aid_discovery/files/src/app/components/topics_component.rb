# frozen_string_literal: true

# Renders subjects and topics for record.
class TopicsComponent < ViewComponent::Base
  attr_accessor :topics

  # @param [Array<String>] topics
  def initialize(topics:)
    @topics = topics
  end

  def render?
    topics.any?
  end

  def call
    render(CollapsableSectionComponent.new(id: t('sections.topics').parameterize)) do |c|
      c.title { t('sections.topics') }
      c.body { topics_list }
    end
  end

  def topics_list
    content_tag :ul, class: 'list-unstyled' do
      safe_join topics.map { |t| content_tag(:li, t) }
    end
  end
end