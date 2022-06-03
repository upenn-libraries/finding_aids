# frozen_string_literal: true

FactoryBot.define do
  factory :solr_document do
    id { "test-endpoint_#{Faker::File.unique.file_name(ext: '')}" }
    endpoint_ssi { 'test-endpoint' }
    xml_ss { '' }
    link_url_ss { '' }
    ead_id_ssi { '' }
    unit_id_ssi { 'TE-Foo. 1234' }
    pretty_unit_id_ss { '1234' }
    contact_emails_ssm { [Faker::Internet.email] }
    title_tsi { Faker::Book.title }
    extent_ssi { '1 bushel' }
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
end
