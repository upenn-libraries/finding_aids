# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Catalog::ConstraintsComponent, type: :component do
  subject(:component) { described_class.new(**params) }

  before { render_inline(component) }

  let(:params) do
    { search_state: search_state }
  end

  let(:search_state) do
    Blacklight::SearchState.new(query_params.with_indifferent_access,
                                Blacklight::Configuration.new)
  end
  let(:query_params) { {} }

  it 'renders a heading with no CSS classes' do
    heading = page.find('h2')
    expect(heading[:class].to_s).to be_empty
  end

  context 'with no constraints' do
    describe '#render?' do
      it 'is true' do
        expect(component.render?).to be true
      end
    end

    it 'renders an "All" query constraint' do
      expect(page).to have_css('span.filter-value', text: I18n.t('blacklight.search.filters.all'))
    end

    it 'links to the home page when "All" constraint is removed' do
      expect(page).to have_css("a.remove[href='#{component.helpers.root_path}']")
    end
  end

  context 'with a query' do
    let(:query_params) { { q: 'some query' } }

    it 'does not render the "All" query constraint' do
      expect(page).not_to have_css('span.filter-value', text: I18n.t('blacklight.search.filters.all'))
    end
  end
end
