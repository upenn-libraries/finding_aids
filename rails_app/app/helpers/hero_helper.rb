# frozen_string_literal: true

# Builds the responsive sources for the homepage hero picture.
#
module HeroHelper
  WIDE_WIDTHS = [1600, 2000, 2400].freeze
  WIDE_CROP_MEDIA = '(min-width: 48em)'
  HERO_IMAGE_DIR = 'heroes'

  # @param image [Config::Options] an entry from Settings.homepage_images
  # @return [String] srcset for the wide crop, omitting widths that aren't generated
  def hero_wide_srcset(image)
    WIDE_WIDTHS.filter_map { |width|
      path = hero_image_path(image, "wide-#{width}w")
      "#{path} #{width}w" if path
    }.join(', ')
  end

  # @param image [Config::Options] an entry from Settings.homepage_images
  # @return [String, nil]
  def hero_narrow_path(image)
    hero_image_path(image, 'narrow')
  end

  # @param image [Config::Options] an entry from Settings.homepage_images
  # @param variant [String] e.g. "wide-1600w" or "narrow"
  # @return [String, nil] asset path, or nil when the file doesn't exist
  def hero_image_path(image, variant)
    filename = "#{image.basename}-#{variant}.webp"
    return unless Rails.root.join('app/assets/images', HERO_IMAGE_DIR, filename).exist?

    image_path("#{HERO_IMAGE_DIR}/#{filename}")
  end
end
