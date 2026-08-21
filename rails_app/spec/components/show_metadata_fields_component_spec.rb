# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ShowMetadataFieldsComponent, type: :component do
  let(:field) { instance_double(Blacklight::FieldPresenter, label: 'Title', render: values) }
  let(:fields) { [field] }

  context 'when fields are present' do
    let(:values) { ['Sample value'] }

    it 'renders a definition list with the label and value' do
      render_inline(described_class.new(fields: fields))

      expect(page).to have_css('dl.pl-dl dt', text: 'Title')
      expect(page).to have_css('dl.pl-dl dd', text: 'Sample value')
    end

    it 'applies a custom dl class when given' do
      render_inline(described_class.new(fields: fields, dl_class: 'custom-dl'))

      expect(page).to have_css('dl.custom-dl')
      expect(page).to have_no_css('dl.pl-dl')
    end

    it 'applies a custom dt class when given' do
      render_inline(described_class.new(fields: fields, dt_class: 'custom-dt'))

      expect(page).to have_css('dt.custom-dt')
    end

    it 'does not wrap fields in an extra tag when wrapper_tag is not given' do
      render_inline(described_class.new(fields: fields))

      expect(page).to have_css('dl > dt')
    end

    it 'wraps each field in the given wrapper_tag when provided' do
      render_inline(described_class.new(fields: fields, wrapper_tag: :div))

      expect(page).to have_css('dl > div > dt')
    end
  end

  context 'with multiple distinct values' do
    let(:values) { %w[Cats Dogs] }

    it 'renders multiple values for a single field as separate dd elements' do
      render_inline(described_class.new(fields: fields))

      expect(page).to have_css('dd', text: 'Cats')
      expect(page).to have_css('dd', text: 'Dogs')
    end

    it 'renders a dt/dd pair for each field in order' do
      second_field = instance_double(Blacklight::FieldPresenter, label: 'Creator', render: ['Jane Doe'])

      render_inline(described_class.new(fields: [field, second_field]))

      labels = page.all('dt').map(&:text)
      expect(labels).to eq(%w[Title Creator])
    end
  end

  context 'when the truncate option is true' do
    let(:values) { Array.new(described_class::LIST_LENGTH_LIMIT + 1) { 'Sample title' } }

    it 'truncates the list' do
      render_inline(described_class.new(fields: fields, truncate: true))
      labels = page.all('dd').map(&:text)
      expect(labels.length).to eq(described_class::LIST_LENGTH_LIMIT)
    end

    it 'includes a link as the last array element' do
      render_inline(described_class.new(fields: fields, truncate: true))
      labels = page.all('dd').map(&:text)
      expect(labels.last).to match(/#{I18n.t('show.sections.overview.see_all_entries', field: field.label)}/)
    end
  end

  context 'when fields are empty' do
    let(:fields) { [] }

    it 'does not render the component' do
      render_inline(described_class.new(fields: fields))

      expect(page).to have_no_css('dl')
    end
  end
end
