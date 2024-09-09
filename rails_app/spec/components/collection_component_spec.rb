# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionComponent, type: :component do
  subject { page }

  let(:fragment) { Nokogiri::XML.fragment(xml) }

  before do
    render_inline(
      described_class.new(
        node: fragment, level: 1, index: 1, id: 'test', requestable: true
      )
    )
  end

  context 'with a single container' do
    let(:xml) do
      <<XML
      <c>
        <did>
          <container type="box">1</container>
        </did>
      </c>
XML
    end

    it 'shows a checkbox with the expected name value' do
      expect(page).to have_field 'c[Box_1]'
    end
  end

  context 'with two containers' do
    let(:xml) do
      <<XML
      <c>
        <did>
          <container type="box">1</container>
          <container type="folder">1</container>
        </did>
      </c>
XML
    end

    it 'shows a checkbox with the expected name value' do
      expect(page).to have_field 'c[Box_1][Folder_1]'
    end
  end

  context 'with three containers' do
    let(:xml) do
      <<XML
      <c>
        <did>
          <container type="drawer">1</container>
          <container type="box">1</container>
          <container type="folder">1</container>
        </did>
      </c>
XML
    end

    it 'shows a checkbox with the expected name value' do
      expect(page).to have_field 'c[Drawer_1][Box_1][Folder_1]'
    end
  end

  context 'with digital objects in EAD v3 style' do
    # NOTE: `xlink` namespaces used in dao nodes will be stripped when EAD is stored in Solr, as it is in EadParser
    let(:xml) do
      <<XML
    <c>
      <did>
        <unittitle>Collection with DOs</unittitle>
        <unitid audience="internal" identifier="250031">250031</unitid>
        <unitdate datechar="creation">undated</unitdate>
        <container label="Mixed Materials" type="box">2</container>
        <container type="Folder">4-7</container>
        <dao audience="internal" actuate="onRequest" href="https://colenda.library.upenn.edu/catalog/a" show="new" title="Notebook A" type="simple">
          <daodesc><p>Notebook A</p></daodesc>
        </dao>
        <dao audience="internal" actuate="onRequest" href="https://colenda.library.upenn.edu/catalog/b" show="new" title="Notebook B" type="simple" role="https://iiif.io/api/presentation/2.1/">
          <daodesc><p>Notebook B</p></daodesc>
        </dao>
      </did>
    </c>
XML
    end

    it { is_expected.to have_link 'Notebook A', href: 'https://colenda.library.upenn.edu/catalog/a' }
    it { is_expected.to have_link 'Notebook B', href: 'https://colenda.library.upenn.edu/catalog/b', class: 'iiif-manifest-link' }
  end

  context 'with digital objects in EAD v2 style' do
    # NOTE: `xlink` namespaces used in dao nodes will be stripped when EAD is stored in Solr, as it is in EadParser
    let(:xml) do
      <<XML
    <c>
      <did>
        <unittitle>Collection with DOs</unittitle>
        <unitid audience="internal" identifier="250031">250031</unitid>
        <unitdate datechar="creation">undated</unitdate>
        <container label="Mixed Materials" type="box">2</container>
        <container type="Folder">4-7</container>
      </did>
      <dao audience="internal" actuate="onRequest" href="https://colenda.library.upenn.edu/catalog/a" show="new" title="Notebook A" type="simple">
        <daodesc><p>Notebook A</p></daodesc>
      </dao>
      <dao audience="internal" actuate="onRequest" href="https://colenda.library.upenn.edu/catalog/b" show="new" title="Notebook B" type="simple" role="https://iiif.io/api/presentation/2.1/">
        <daodesc><p>Notebook B</p></daodesc>
      </dao>
    </c>
XML
    end

    it { is_expected.to have_link 'Notebook A', href: 'https://colenda.library.upenn.edu/catalog/a' }
    it { is_expected.to have_link 'Notebook B', href: 'https://colenda.library.upenn.edu/catalog/b', class: 'iiif-manifest-link' }
  end

  context 'with digital objects containing invalid href values' do
    let(:xml) do
      <<XML
    <c>
      <did>
        <unittitle>Collection with DOs</unittitle>
        <unitid audience="internal" identifier="250031">250031</unitid>
        <unitdate datechar="creation">undated</unitdate>
        <container label="Mixed Materials" type="box">2</container>
        <container type="Folder">4-7</container>
      </did>
      <dao audience="internal" actuate="onRequest" href="123456789" show="new" title="Notebook A" type="simple">
        <daodesc><p>Notebook A</p></daodesc>
      </dao>
      <dao audience="internal" actuate="onRequest" href="/path/to/something" show="new" title="Notebook B" type="simple">
        <daodesc><p>Notebook B</p></daodesc>
      </dao>
    </c>
XML
    end

    it { is_expected.not_to have_link 'Notebook A' }
    it { is_expected.not_to have_link 'Notebook B' }
  end
end
