# frozen_string_literal: true

# Custom hero component that renders a header, a picture, and a heading over a
# full-bleed image. Used on the homepage (see catalog/_home.html.erb) via the base
# layout's :header content slot. Mirrors Digital Collections' HeaderHeroComponent.
class HeaderHeroComponent < Blacklight::Component
  attr_accessor :blacklight_config

  renders_one :header, lambda {
    HeaderComponent.new(blacklight_config: blacklight_config, theme: :dark)
  }
  renders_one :picture
  renders_one :heading
  renders_one :subheading

  # @param blacklight_config [Blacklight::Configuration]
  def initialize(blacklight_config:)
    @blacklight_config = blacklight_config
  end

  def before_render
    with_header unless header
    with_picture unless picture
    with_heading unless heading
    with_subheading unless subheading
  end
end
