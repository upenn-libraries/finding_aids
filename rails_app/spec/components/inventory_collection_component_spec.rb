# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InventoryCollectionComponent, type: :component do
  include EadHelpers

  describe 'rendering' do
    it 'renders the "not available" alert when given no entries' do
      render_inline(described_class.new(entries: []))
      expect(page).to have_css('#inventory-accordion div[role="alert"]', text: I18n.t('show.sections.inventory.none'))
    end

    it 'renders one InventoryComponent per entry when entries are given' do
      entries = [
        entry_for('<c01 level="series"><did><unittitle>Series One</unittitle></did></c01>'),
        entry_for('<c01 level="series"><did><unittitle>Series Two</unittitle></did></c01>')
      ]

      render_inline(described_class.new(entries: entries))

      expect(page).to have_css('#inventory-accordion details.fa-guide__details summary h3#series-1', text: 'Series One')
      expect(page).to have_css('#inventory-accordion details.fa-guide__details summary h3#series-2', text: 'Series Two')
    end

    it 'forwards requestable to each rendered InventoryComponent' do
      entries = [entry_for('<c01 level="series"><did><unittitle>Series One</unittitle></did></c01>')]

      render_inline(described_class.new(entries: entries, requestable: true))

      expect(page).to have_css('th', text: 'Select', visible: :all)
    end

    it 'wraps everything in the pennlibs-accordion custom element' do
      render_inline(described_class.new(entries: []))

      expect(page).to have_css('pennlibs-accordion#inventory-accordion')
    end
  end
end
