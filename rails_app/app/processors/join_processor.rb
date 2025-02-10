# frozen_string_literal: true

# Custom Blacklight Join step to return an array for JSON requests
# This overrides app/presenters/blacklight/rendering/join.rb from the Blacklight gem
# and must be updated if the original file is modified.
# rubocop:disable Metrics
class JoinProcessor < Blacklight::Rendering::AbstractStep
  include ActionView::Context
  include ActionView::Helpers::TextHelper

  def render
    return next_step(values) if json_request?

    options = config.separator_options || {}
    if values.one? || values.none?
      next_step(values.first)
    elsif !html?
      next_step(values.to_sentence(options))
    else
      next_step(values.map { |x| x.html_safe? ? x : html_escape(x) }.to_sentence(options).html_safe)
    end
  end

  private

  def html_escape(*args)
    ERB::Util.html_escape(*args)
  end

  # @return [Boolean, nil]
  def json_request?
    # `context` in some cases (e.g. mailing a record) does not have a search_state defined
    return false unless context.respond_to?(:search_state)

    context.search_state&.params&.dig(:format) == 'json'
  end
end
# rubocop:enable Metrics
