# frozen_string_literal: true

FactoryBot.define do
  factory :solr_document do
    id { "test-endpoint_#{Faker::File.unique.file_name(ext: '').tr('/', '-')}" }
    legacy_ids_ssim { ['UPENN_PUUSTEFOO1234'] }
    endpoint_ssi { 'test-endpoint' }
    xml_ss { '' }
    link_url_ss { '' }
    ead_id_ssi { '' }
    unit_id_tsi { 'TE-Foo. 1234' }
    pretty_unit_id_ss { '1234' }
    contact_emails_ssm { [Faker::Internet.email] }
    title_tsi { Faker::Book.title }
    extent_ssim { ['1 bushel'] }
    display_date_ssim { '1800' }
    years_iim { [1800] }
    date_added_ss { '' }
    languages_ssim { %w[English Gullah] }
    abstract_scope_contents_tsi { Faker::Lorem.sentence }
    preferred_citation_ss { '' }
    repository_ssi { 'Test Institute:Research Center:Individual Room' }
    creators_ssim { ['A Machine'] }
    people_ssim { ['A Tester'] }
    places_ssim { ['The Internet'] }
    corpnames_ssim { [] }
    subjects_ssim { ['Testing'] }
    upenn_record_bsi { false }
    repository_name_component_1_ssi { 'Test Institute' }
    repository_name_component_2_ssi { 'Research Center' }
    repository_name_component_3_ssi { 'Individual Room' }
    donors_ssim { ['A Donor'] }
    genre_form_ssim { 'Imaginary Substance' }
    names_ssim { ['A Machine', 'A Tester', 'A Donor'] }
  end

  trait :requestable do
    repository_ssi { AeonRequest::KISLAK_REPOSITORY_NAME }
  end

  trait :with_collection_data do
    xml_ss do
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <ead xsi:schemaLocation="urn:isbn:1-931666-22-9 http://www.loc.gov/ead/ead.xsd"
           xmlns:ns2="http://www.w3.org/1999/xlink" xmlns="urn:isbn:1-931666-22-9"
           xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <eadheader findaidstatus="Under_revision" repositoryencoding="iso15511" countryencoding="iso3166-1"
                   dateencoding="iso8601" langencoding="iso639-2b">
          <eadid url="https://www.test.com"></eadid>
        </eadheader>
        <archdesc level="collection">
          <did></did>
          <scopecontent id="ref177"></scopecontent>
          <bioghist id="ref176"></bioghist>
          <controlaccess></controlaccess>
          <dsc>
            <c id="ref1" level="series">
              <did>
                <unittitle>Test Collection</unittitle>
                <langmaterial>
                  <language langcode="eng"/>
                </langmaterial>
                <unitdate normal="1900/1950" type="inclusive">1900-1950</unitdate>
              </did>
              <c id="ref2" level="file">
                <did>
                  <unittitle>Something Really Distinctive</unittitle>
                  <langmaterial>
                    <language langcode="eng"/>
                  </langmaterial>
                  <container type="Box">1</container>
                </did>
              </c>
            </c>
          </dsc>
        </archdesc>
      </ead>'
    end
  end

  trait :with_ead3_collection_data do
    xml_ss do
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <ead xsi:schemaLocation="urn:isbn:1-931666-22-9 http://www.loc.gov/ead/ead.xsd"
           xmlns:ns2="http://www.w3.org/1999/xlink" xmlns="urn:isbn:1-931666-22-9"
           xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <eadheader findaidstatus="Under_revision" repositoryencoding="iso15511" countryencoding="iso3166-1"
                   dateencoding="iso8601" langencoding="iso639-2b">
          <eadid url="https://www.test.com"></eadid>
        </eadheader>
        <archdesc level="collection">
          <did></did>
          <scopecontent id="ref177"></scopecontent>
          <bioghist id="ref176"></bioghist>
          <controlaccess></controlaccess>
          <dsc>
            <c id="ref1" level="series">
              <did>
                <unittitle>Test Collection</unittitle>
                <langmaterial>
                  <language langcode="eng"/>
                </langmaterial>
                <unitdatestructured>
                  <dateset>
                  <daterange>
                  <fromdate>2000</fromdate>
                  <todate>2010</todate>
                  <datesingle>2005</datesingle>
                  </daterange>
                  </dateset>
                </unitdatestructured>
                <physdescset>
                <physdescstructured coverage="part" physdescstructuredtype="materialtype">
                  <quantity>143</quantity>
                  <unittype>electronic files</unittype>
                  </physdescstructured>
                <physdescstructured coverage="part" physdescstructuredtype="materialtype">
                  <quantity>6</quantity>
                  <unittype>compact discs</unittype>
                </physdescstructured>
                </physdescset>
              </did>
              <c id="ref2" level="file">
                <did>
                  <unittitle>Something Really Distinctive</unittitle>
                  <langmaterial>
                    <language langcode="eng"/>
                  </langmaterial>
                  <container type="Box">1</container>
                  <unitdatestructured type="bulk">
                    <datesingle>2001</datesingle>
                  </unitdatestructured>
                </did>
              </c>
            </c>
          </dsc>
        </archdesc>
      </ead>'
    end
  end
end
