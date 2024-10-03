# frozen_string_literal: true

require 'rails_helper'

describe 'Penn vanity route' do
  it 'routes to the search results with the penn source facet applied' do
    get penn_path
    expect(response).to redirect_to search_catalog_path({ 'f[record_source][]': 'upenn' })
  end
end
