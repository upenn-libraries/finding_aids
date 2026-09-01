# frozen_string_literal: true

# Render a <picture> tag with sources and required image tag for Hero art direction.
# See the `homepage_images` config for the data structure expected for use with this object.
class HeroPictureComponent < Blacklight::Component
  attr_accessor :image

  SOURCE_SIZE = '100vw'

  # @param image_data [Config::Options] data about the image and it's alternate versions
  def initialize(image_data:)
    @image = image_data
  end

  def call
    picture_tag hero: 'art-direction' do
      safe_join(image.sources.map { |source|
        tag.source srcset: srcset_from(source), media: source.media, sizes: SOURCE_SIZE
      } << default_image)
    end
  end

  private

  # @return [String] alternate image version data formatted for use in a srcset attribute
  #                  see: https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/srcset
  def srcset_from(source)
    source.srcset
          .map { |e| "#{image_path(e.file)} #{e.descriptor}" }
          .join(', ')
  end

  def default_image
    image_tag image.default, alt: image.alt_text
  end
end
