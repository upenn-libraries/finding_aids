# frozen_string_literal: true

require 'system_helper'

describe 'Endpoint dashboard' do
  let!(:endpoint_success)  { create(:endpoint, :webpage_harvest, :complete_harvest) }
  let!(:endpoint_failed)   { create(:endpoint, :webpage_harvest, :failed_harvest) }
  let!(:endpoint_removals) { create(:endpoint, :webpage_harvest, :harvest_with_removals) }
  let(:test_endpoints) do
    [endpoint_success, endpoint_failed, endpoint_removals]
  end

  after { Endpoint.delete_all }

  context 'when visiting index page' do
    before { visit endpoints_status_path }

    it 'renders all endpoint slugs' do
      test_endpoints.each do |endpoint|
        within ".table-row-#{endpoint.slug}" do
          expect(page).to have_text endpoint.slug
        end
      end
    end

    it 'renders links to endpoint show pages' do
      test_endpoints.each do |endpoint|
        within ".table-row-#{endpoint.slug}" do
          expect(page).to have_link endpoint.slug, href: endpoint_status_path(endpoint.slug)
        end
      end
    end

    it 'shows error message text for problem harvest' do
      within ".table-row-#{endpoint_failed.slug}" do
        expect(page).to have_text endpoint_failed.last_harvest.errors.first
      end
    end

    it 'shows a count of removed records' do
      within ".table-row-#{endpoint_removals.slug}" do
        expect(page).to have_text "removed #{endpoint_removals.last_harvest.removed_files.count} record"
      end
    end
  end

  context 'when visiting show page' do
    context 'with removals' do
      before { visit endpoint_status_path(endpoint_removals.slug) }

      it 'lists removed ids' do
        endpoint_removals.last_harvest.removed_files.each do |removed_file|
          within '#removed-records-list' do
            expect(page).to have_text removed_file['id']
          end
        end
      end
    end
  end
end
