# frozen_string_literal: true

describe JoinProcessor do
  let(:config) { Blacklight::Configuration::Field.new(key: 'field') }
  let(:context) { OpenStruct.new(search_state: instance_double(Blacklight::SearchState, params: params)) }
  let(:processor) do
    described_class.new(values, config, SolrDocument.new, context,
                        { context: 'show' }, [Blacklight::Rendering::Terminator])
  end

  context 'with a JSON request' do
    let(:params) { { format: 'json' } }

    context 'with multiple values' do
      let(:values) { ['Chapter 1', 'Chapter 2'] }

      it 'returns an array of untransformed values' do
        expect(processor.render).to eq values
      end
    end
  end
end
