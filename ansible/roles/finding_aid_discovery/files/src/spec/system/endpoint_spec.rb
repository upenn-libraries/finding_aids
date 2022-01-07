require 'system_helper'

describe 'Endpoint dashboard' do
  let!(:endpoint_success) do
    FactoryBot.create(:endpoint, :index_harvest, :successful_harvest)
  end
  let!(:endpoint_failed) do
    FactoryBot.create(:endpoint, :index_harvest, :failed_harvest)
  end
  let!(:endpoint_problem) do
    FactoryBot.create(:endpoint, :index_harvest, :harvest_with_file_problem)
  end
  let!(:endpoint_removals) do
    FactoryBot.create(:endpoint, :index_harvest, :harvest_with_removals)
  end
  let(:test_endpoints) do
    [endpoint_success, endpoint_failed, endpoint_problem, endpoint_removals]
  end
  after do
    Endpoint.delete_all
  end
  context 'index' do
    before do
      visit endpoints_path
    end
    it 'renders all endpoint slugs' do
      test_endpoints.each do |endpoint|
        expect(page).to have_text endpoint.slug
      end
    end
    it 'renders links to endpoint show pages' do
      test_endpoints.each do |endpoint|
        expect(page).to have_link endpoint.slug, href: endpoint_path(endpoint.slug)
      end
    end
    it 'shows error message text for problem harvest' do
      expect(page).to have_text endpoint_failed.last_harvest_errors.first
    end
    it 'shows a count of removed records' do
      expect(page).to have_text "removed #{endpoint_removals.last_harvest_removed_ids.count} record"
    end
  end
  context 'show' do
    context 'removals' do
      before { visit endpoint_path(endpoint_removals.slug) }
      it 'lists removed ids' do
        endpoint_removals.last_harvest_removed_ids.each do |removed_id|
          expect(page).to have_text removed_id
        end
      end
    end
  end

end
