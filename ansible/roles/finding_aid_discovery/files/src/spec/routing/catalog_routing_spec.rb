# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'catalog' do
  describe 'show' do
    it 'routes to catalog_controller#show with an id that includes a period' do
      id_with_period = 'ead.from.org'
      expect(get: "/catalog/#{id_with_period}").to route_to(
        controller: 'catalog', action: 'show',
        id: id_with_period
      )
    end
  end
end
