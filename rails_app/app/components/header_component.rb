# frozen_string_literal: true

# Header component using Penn Libraries design system header web component
# and a simplified search bar (no advanced search, no autocomplete).
class HeaderComponent < Blacklight::Component
  renders_one :search_bar, lambda { |component: SearchNavbarComponent|
    component.new(blacklight_config: blacklight_config)
  }

  attr_reader :blacklight_config

  delegate :current_user, to: :helpers

  def initialize(blacklight_config:)
    @blacklight_config = blacklight_config
  end

  def before_render
    with_search_bar unless search_bar
  end
end
