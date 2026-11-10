# frozen_string_literal: true

RSpec.describe(Catalog::LanguageNotePresenter) do
  let(:field_config) { CatalogController.new.blacklight_config.show_fields[:language_note] }
  let(:view_context) { CatalogController.new.view_context }
  let(:document) do
    SolrDocument.new(attributes_for(:solr_document, languages_ssim: %w[English French], xml_ss: xml_ss))
  end
  let(:presenter) { described_class.new(view_context, document, field_config) }

  describe '#render?' do
    context 'with language note different than indexed language field' do
      let(:xml_ss) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <ead xsi:schemaLocation="urn:isbn:1-931666-22-9 http://www.loc.gov/ead/ead.xsd">
            <archdesc level="collection">
              <did>
                <langmaterial>
                  Mostly in <language langcode="eng">English</language>, but some materials contain Esperanto.
                </langmaterial>
              </did>
              <dsc><c id="ref1" level="series"></c></dsc>
            </archdesc>
          </ead>
        XML
      end

      it 'renders the language note' do
        expect(presenter.render_field?).to be true
      end
    end

    context 'when language note is the same as languages field' do
      let(:xml_ss) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <ead xsi:schemaLocation="urn:isbn:1-931666-22-9 http://www.loc.gov/ead/ead.xsd">
            <archdesc level="collection">
              <did>
                <langmaterial>
                 <language langcode="eng">English</language>
                 <language langcode="fre">French</language>
                </langmaterial>
              </did>
              <dsc><c id="ref1" level="series"></c></dsc>
            </archdesc>
          </ead>
        XML
      end

      it 'does not render the language note' do
        expect(presenter.render_field?).to be false
      end
    end
  end
end
