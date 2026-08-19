# frozen_string_literal: true

require 'rails_helper'

describe HeroHelper do
  let(:image) { Settings.homepage_images.first }
  let(:missing_image) { Config::Options.new(basename: 'no-such-image') }

  describe '#hero_wide_srcset' do
    it 'pairs each generated width with its w descriptor' do
      expect(helper.hero_wide_srcset(image)).to match(/moelis-reading-room-wide-1600w\S*\.webp 1600w/)
    end

    it 'omits widths with no generated file rather than upscaling' do
      expect(helper.hero_wide_srcset(image)).not_to include '2400w'
    end

    it 'is empty when an image has no derivatives' do
      expect(helper.hero_wide_srcset(missing_image)).to eq ''
    end
  end

  describe '#hero_narrow_path' do
    it 'returns the asset path for the narrow crop' do
      expect(helper.hero_narrow_path(image)).to match(%r{heroes/moelis-reading-room-narrow\S*\.webp})
    end

    it 'returns nil when an image has no narrow crop' do
      expect(helper.hero_narrow_path(missing_image)).to be_nil
    end
  end
end
