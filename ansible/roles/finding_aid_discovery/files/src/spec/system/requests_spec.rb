# frozen_string_literal: true

require 'system_helper'

describe 'Requests' do
  context 'when using the request form' do
    before do
      visit new_request_path(collection_form_params)
    end

    context 'with a single container request' do
      let(:collection_form_params) do
        {
          c: { 'Box_1' => { 'Album_2' => '1' } },
          call_num: 'Ms. Coll. 12345',
          repository: AeonRequest::KISLAK_REPOSITORY_NAME,
          title: 'Test Title'
        }
      end

      it 'takes user to PennKey login page' do
        click_button I18n.t('requests.form.fields.submit')
        expect(page).to have_text 'PennKey'
      end

      it 'takes user to Aeon login page' do
        choose I18n.t('requests.form.fields.external_auth')
        click_button I18n.t('requests.form.fields.submit')
        expect(page).to have_button 'Logon to Aeon'
      end
    end
  end
end
