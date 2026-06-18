# frozen_string_literal: true

# Header component using Penn Libraries design system header web component
# and a simplified search bar (no advanced search, no autocomplete).
class HeaderComponent < Blacklight::Component
  renders_one :search_bar, lambda { |component: Catalog::SearchNavbarComponent|
    component.new(blacklight_config: blacklight_config)
  }

  attr_reader :blacklight_config, :user, :theme

  # @param theme [Symbol] :light (default) or :dark — passed to the pennlibs-header
  #   web component. The homepage hero renders a :dark header (see HeaderHeroComponent).
  def initialize(blacklight_config:, user: nil, theme: :light)
    @blacklight_config = blacklight_config
    @user = user
    @theme = theme
  end

  def before_render
    with_search_bar unless search_bar
  end
end
