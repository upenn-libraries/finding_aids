# frozen_string_literal: true

require 'rails_helper'

describe ApplicationHelper do
  describe '#full_page_title' do
    let(:application_name) { I18n.t('blacklight.application_name') }
    let(:organization_name) { I18n.t('blacklight.organization_name') }

    context 'when a page-specific title is set via content_for' do
      before { helper.content_for(:page_title, 'Civil War') }

      it 'follows the "Page name · Application name · Penn Libraries" pattern' do
        expect(helper.full_page_title).to eq "Civil War · #{application_name} · #{organization_name}"
      end
    end

    context 'when a page-specific title is passed in (e.g. the layout forwarding @page_title)' do
      it 'follows the full pattern' do
        expect(helper.full_page_title('About')).to eq "About · #{application_name} · #{organization_name}"
      end
    end

    context 'when a content_for title is set, it takes precedence over the passed-in title' do
      before { helper.content_for(:page_title, 'Civil War') }

      it 'uses the content_for title' do
        expect(helper.full_page_title('About')).to eq "Civil War · #{application_name} · #{organization_name}"
      end
    end

    context 'when a content_for title contains surrounding whitespace' do
      before { helper.content_for(:page_title, "\n  About\n") }

      it 'strips the whitespace from the page-name segment' do
        expect(helper.full_page_title).to eq "About · #{application_name} · #{organization_name}"
      end
    end

    context 'when no page-specific title is set (e.g. the homepage)' do
      it 'collapses to the "Application name · Penn Libraries" variant' do
        expect(helper.full_page_title).to eq "#{application_name} · #{organization_name}"
      end
    end
  end
end
