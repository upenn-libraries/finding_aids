# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'catalog' do
  let(:ead_id_with_period) { 'ead.from.org' }
  describe 'show' do
    it 'routes to catalog_controller#show with an id that includes a period' do
      expect(get: "/catalog/#{ead_id_with_period}").to route_to(
        controller: 'catalog', action: 'show',
        id: ead_id_with_period
      )
    end
  end

  describe 'track' do
    it 'routes to catalog_controller#track with an id that includes a period' do
      id_with_period = 'ead.from.org'
      expect(post: "/catalog/#{ead_id_with_period}/track").to route_to(
        controller: 'catalog', action: 'track',
        id: ead_id_with_period
      )
    end
  end
end
