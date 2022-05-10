# frozen_string_literal: true

require 'rails_helper'

describe AeonRequest do
  let(:request) { AeonRequest.new(params) }

  describe '#submit' do
    context 'with some sample params' do
      let(:params) do
        ActionController::Parameters.new({
           title_callnum_location: 'issue_volume' # ???
        })
      end

      it 'works' do
        expect(:request).to be_a AeonRequest
      end
    end
  end

end
