# frozen_string_literal: true

require 'system_helper'

shared_examples_for 'endpoint show page' do
  before { visit endpoint_path(endpoint) }

  it 'links to edit page' do
    expect(page).to have_link(I18n.t('admin.actions.edit'), count: 1)
  end

  it 'displays the slug' do
    expect(page).to have_text endpoint.slug
  end

  it 'displays the source type' do
    expect(page).to have_text endpoint.source_type
  end

  it 'displays the contacts' do
    expect(page).to have_text endpoint.public_contacts.join(', ')
    expect(page).to have_text endpoint.tech_contacts.join(', ')
  end

  it 'links to the last harvest results' do
    expect(page).to have_link(I18n.t('admin.endpoints.last_harvest_results'), href: endpoint_status_path(endpoint.slug))
  end
end

describe 'Endpoints show page' do
  let(:user) { create(:user) }

  before { sign_in user }

  context 'when visiting the show page of an webpage endpoint' do
    let(:webpage_endpoint) { create(:endpoint, :webpage_harvest) }

    it_behaves_like 'endpoint show page' do
      let(:endpoint)  { webpage_endpoint }
    end

    before { visit endpoint_path(webpage_endpoint) }

    it 'links to the webpage url' do
      expect(page).to have_link(webpage_endpoint.webpage_url, href: webpage_endpoint.webpage_url)
    end
  end

  context 'when visiting the show page of an aspace endpoint' do
    let(:aspace_endpoint) { create(:endpoint, :aspace_harvest) }

    it_behaves_like 'endpoint show page' do
      let(:endpoint)  { aspace_endpoint }
    end

    before { visit endpoint_path(aspace_endpoint) }

    it 'links to ASpace instance' do
      expect(page).to have_link(aspace_endpoint.aspace_instance.slug,
                                href: aspace_instance_path(aspace_endpoint.aspace_instance))
    end
  end
end
