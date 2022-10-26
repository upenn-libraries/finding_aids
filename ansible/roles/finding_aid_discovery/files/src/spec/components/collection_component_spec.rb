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
    # NOTE: `xlink` namespaces used in dao nodes will be stripped when EAD is stored in Solr, is it is in EadParser
    let(:xml) do
      <<XML
    <c>
      <did>
        <unittitle>Collection with DOs</unittitle>
        <unitid audience="internal" identifier="250031">250031</unitid>
        <unitdate datechar="creation">undated</unitdate>
        <container label="Mixed Materials" type="box">2</container>
        <container type="Folder">4-7</container>
        <dao audience="internal" actuate="onRequest" href="https://colenda.library.upenn.edu/catalog/81431-p3zs2ks92" show="new" title="Robert Agnew (possibly) notebook, approximately 1783-1810 (Volume 1)&#10;" type="simple">
          <daodesc><p>Robert Agnew (possibly) notebook, approximately 1783-1810 (Volume 1)</p></daodesc>
        </dao>
        <dao audience="internal" actuate="onRequest" href="https://colenda.library.upenn.edu/catalog/81431-p3v11w05n" show="new" title="Robert Agnew (possibly) notebook, approximately 1783-1810 (Volume 2)&#10;" type="simple">
          <daodesc><p>Robert Agnew (possibly) notebook, approximately 1783-1810 (Volume 2)</p></daodesc>
        </dao>
      </did>
    </c>
XML
    end

    it { is_expected.to have_link 'Robert Agnew (possibly) notebook, approximately 1783-1810 (Volume 1)' }
    it { is_expected.to have_link 'Robert Agnew (possibly) notebook, approximately 1783-1810 (Volume 2)' }
  end

  context 'with digital objects in EAD v2 style' do
    # NOTE: `xlink` namespaces used in dao nodes will be stripped when EAD is stored in Solr, is it is in EadParser
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
      <dao audience="internal" actuate="onRequest" href="https://colenda.library.upenn.edu/catalog/81431-p3zs2ks92" show="new" title="Robert Agnew (possibly) notebook, approximately 1783-1810 (Volume 1)&#10;" type="simple">
        <daodesc><p>Robert Agnew (possibly) notebook, approximately 1783-1810 (Volume 1)</p></daodesc>
      </dao>
      <dao audience="internal" actuate="onRequest" href="https://colenda.library.upenn.edu/catalog/81431-p3v11w05n" show="new" title="Robert Agnew (possibly) notebook, approximately 1783-1810 (Volume 2)&#10;" type="simple">
        <daodesc><p>Robert Agnew (possibly) notebook, approximately 1783-1810 (Volume 2)</p></daodesc>
      </dao>
    </c>
XML
    end

    it { is_expected.to have_link 'Robert Agnew (possibly) notebook, approximately 1783-1810 (Volume 1)' }
    it { is_expected.to have_link 'Robert Agnew (possibly) notebook, approximately 1783-1810 (Volume 2)' }
  end
end
