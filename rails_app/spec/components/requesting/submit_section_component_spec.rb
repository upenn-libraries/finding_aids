# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Requesting::SubmitSectionComponent, type: :component do
  subject(:component) { page }

  before do
    render_inline(described_class.new(request_type: request_type))
  end

  context 'with a scan request' do
    let(:request_type) { RequestingComponent::SCAN_REQUEST }

    it 'renders the notes field' do
      expect(component).to have_field I18n.t('show.sections.request.notes_label'), visible: :hidden
    end

    it 'renders the user review field' do
      expect(component).to have_field I18n.t('show.sections.request.user_review_label'), visible: :hidden
    end

    it 'does not render the date field' do
      expect(component).to have_no_field I18n.t('show.sections.request.date_label'), visible: :hidden
    end
  end

  context 'with a visit request' do
    let(:request_type) { RequestingComponent::VISIT_REQUEST }

    it 'renders the notes field' do
      expect(component).to have_field I18n.t('show.sections.request.notes_label'), visible: :hidden
    end

    it 'renders the user review field' do
      expect(component).to have_field I18n.t('show.sections.request.user_review_label'), visible: :hidden
    end

    it 'renders the date field' do
      expect(component).to have_field I18n.t('show.sections.request.date_label'), visible: :hidden
    end
  end
end
