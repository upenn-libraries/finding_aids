# frozen_string_literal: true

# Parser for EAD XML
# Known-good support for EAD 1, EAD 2(002), but NOT for EAD 3. See #validate_ead_spec!
class EadParser
  YEARS_REGEX = %r{[a-zA-Z]*\s* # match any preceding text or whitespace
                  (?<begin>\d{4}) # capture 'begin' date if a range
                  \s* # any additional whitespace that may be present
                  (?: # optionally match range component
                    (?:-|to|/) # supported range separators
                    \s* # allow for more white space
                    [a-zA-Z]*\s* # # any more preceding text or whitespace
                    (?<end>\d{4}) # second capture group for 'end' date
                  )?}x

  class ValidationError < StandardError; end

  attr_reader :doc, :endpoint, :xml

  # @param xml [String]
  # @param endpoint [Endpoint]
  def initialize(xml, endpoint)
    doc = Nokogiri::XML.parse xml
    @doc = doc
    validate_ead_spec!
    doc.remove_namespaces!
    @xml = xml
    @endpoint = endpoint
  end

  # Site-wide identifier for an EAD record
  #
  # Each EAD should have a unit id that is unique for that repository. If this is ever not true,
  # the repository needs to fix their data. We are uppercasing the identifiers so they aren't
  # case-sensitive going forward.
  #
  # Note: This is not the same identifier that was used in the previous site.
  #
  # @return [String]
  def id
    id = unit_id&.gsub(/[^A-Za-z0-9.-]/, '')&.upcase
    raise 'Missing unit id' if id.blank?

    "#{endpoint.slug}_#{id}"
  end

  # Legacy ID that was used in the previous site.
  #
  # The previous application union'ed two fields and the order in which those two fields
  # were joined was not consistent. Therefore to cover all of our bases we are generating
  # two possible legacy ids. We are also uppercasing the entire ID so that we can do
  # case-insensitive matching.
  #
  # @return [Array<String>]
  def legacy_ids
    raw_id = ead_id
    raw_id = unit_id if raw_id.blank?
    raw_id = raw_id.gsub(/[^A-Za-z0-9]/, '')

    agency_code = doc.at_xpath('/ead/eadheader/eadid/@mainagencycode').try(:text)&.gsub(/[^A-Za-z0-9]/, '')

    [
      "#{@endpoint.slug}_#{agency_code}#{raw_id}",
      "#{@endpoint.slug}_#{raw_id}#{agency_code}"
    ].map(&:upcase).uniq
  end

  # Not always present...
  # https://www.loc.gov/ead/tglib/elements/eadid.html
  # @return [String]
  def ead_id
    doc.at_xpath('.//eadheader/eadid').try(:text).try(:strip)
  end

  # https://www.loc.gov/ead/tglib/elements/unitid.html
  # @return [String]
  def unit_id
    doc.at_xpath("/ead/archdesc/did/unitid[not(@audience='internal' or @type='aspace_uri')]").try(:text).try(:strip)
  end

  # @return [String]
  def pretty_unit_id
    unit_id.gsub(/^[^.]*\./, '').strip
  end

  # https://www.loc.gov/ead/tglib/elements/unittitle.html
  # @return [String]
  def title
    doc.at_xpath('/ead/archdesc/did/unittitle').try :text
  end

  # https://www.loc.gov/ead/tglib/elements/extent.html
  # @return [Array<String>]
  def extent
    doc.xpath('/ead/archdesc/did/physdesc').filter_map do |node|
      raw1 = node.at_xpath('./extent[1]').try :text
      raw2 = node.at_xpath('./extent[2]').try :text
      next unless raw1 # handle physdesc with no extent

      raw2.blank? ? raw1.downcase : "#{raw1} (#{raw2})".downcase
    end
  end

  # https://www.loc.gov/ead/tglib/elements/unitdate.html
  # @return [Array]
  def display_date
    doc.xpath('/ead/archdesc/did/unitdate').map do |node|
      value = node.text.try(:strip)
      if node.attr(:type).present?
        value = value.downcase.gsub(/^bulk,?/, '').strip
        "#{value} (#{node.attr(:type)})"
      else
        value
      end
    end
  end

  # https://www.loc.gov/ead/tglib/elements/unitdate.html
  # @return [Array]
  def years
    years = doc.xpath('/ead/archdesc/did/unitdate')&.sum([]) do |node|
      val = node.attr('normal') || node.text
      to_years_array val&.strip
    end
    (years || []).uniq.sort
  end

  # https://www.loc.gov/ead/tglib/elements/abstract.html
  # @return [String]
  def abstract_scope_contents
    doc.at_xpath('/ead/archdesc/did/abstract').try(:text).try(:strip) || ''
  end

  # @return [String]
  def date_added
    doc.at_xpath('/ead/eadheader/profiledesc/creation/date')
       .try(:text)
       &.gsub(/T.*/, '')
  end

  # https://www.loc.gov/ead/tglib/elements/prefercite.html
  # @return [String]
  def preferred_citation
    doc.at_xpath('/ead/archdesc/prefercite/p').try(:text).try(:strip)
  end

  # @return [String]
  def repository
    if doc.at_xpath('/ead/archdesc/did/repository/corpname').try(:text).present?
      doc.at_xpath('/ead/archdesc/did/repository/corpname').try(:text).try(:strip)
    else
      doc.at_xpath('/ead/archdesc/did/repository').try(:text).try(:strip)
    end
  end

  # Returns repository address provided, which often times includes phone number, email addresses and urls. For now,
  # we are removing additional information, but in the future we could include it.
  #
  # @return [String]
  def repository_address
    # Attempt to extract repository address, if not found, try to extract publisher address if
    # publisher and repository are the same.
    repository_addresslines = doc.xpath('/ead/archdesc/did/repository/address/addressline')
    publisher_name = doc.at_xpath('/ead/eadheader/filedesc/publicationstmt/publisher').try(:text).try(:strip)

    addresslines = if repository_addresslines.present?
                     repository_addresslines
                   elsif publisher_name.eql?(repository)
                     doc.xpath('/ead/eadheader/filedesc/publicationstmt/address/addressline')
                   end

    return if addresslines.blank?

    # Remove emails, URLs and phone numbers from address.
    addresslines = addresslines.map { |a| a.try(:text).try(:strip) }
                               .delete_if { |a| a.match?(/\(?\d{3}\)?[\s.-]\d{3}[\s.-]\d{4}|@|URL|http/) }
    addresslines.presence&.join(', ')
  end

  # @todo: move normalization to indexer
  # https://www.loc.gov/ead/tglib/elements/origination.html
  # @param show_role [Boolean]
  # @return [Array]
  def creators(show_role: false)
    doc.xpath(".//did/origination[@label='creator' or @label='Creator']/persname |
               .//did/origination[@label='creator' or @label='Creator']/corpname |
               .//did/origination[@label='creator' or @label='Creator']/famname")
       .map { |node|
         raw_name = node.text.try(:strip)
         raw_role = node.at_xpath('./@role').try(:text).try(:strip)
         if raw_role && show_role
           role = raw_role.gsub(/\(.*$/, '').strip
           "#{raw_name} (#{role})"
         else
           raw_name
         end
       }.uniq
  end

  # TODO: determine what distinguishes this from the people/corp_names fields, functionally
  #       and if this is still warranted
  def names
    doc.xpath(".//controlaccess/persname | .//controlaccess/famname |
               .//controlaccess/corpname | //origination[@label='creator' or @label='Creator']").map { |node|
      node.text.try(:strip)
    }.uniq
  end

  # @return [Array]
  def people
    doc.xpath('.//controlaccess/persname | .//controlaccess/famname')
       .map { |node| node.text.try(:strip) }
       .uniq
  end

  # @return [Array]
  def corp_names
    doc.xpath('.//controlaccess/corpname')
       .map { |node| node.text.try(:strip) }
       .uniq
  end

  # @return [Array]
  def subjects
    doc.xpath('.//controlaccess/subject')
       .map { |node| node.text.strip.gsub(/\s*\.\s*$/, '') }
       .uniq
  end

  # @return [Array]
  def places
    doc.xpath('.//controlaccess/geogname')
       .map { |node| node.text.try(:strip) }
       .uniq
  end

  # @return [Array]
  def occupations
    doc.xpath('.//controlaccess/occupation')
       .map { |node| node.text.try(:strip) }
       .uniq
  end

  # https://www.loc.gov/ead/tglib/elements/language.html
  # @return [Array]
  def languages
    doc.xpath('/ead/archdesc/did/langmaterial/language/@langcode').map { |node|
      code = node.text.try(:strip).try(:downcase)
      iso_entry = ISO_639.find code
      iso_entry&.english_name || code
    }.uniq
  end

  # @return [Array]
  def donor
    doc.xpath(".//controlaccess/persname[@role='Donor (dnr)']")
       .map { |node| node.text.try(:strip) }
       .uniq
  end

  # https://www.loc.gov/ead/tglib/elements/genreform.html
  # @return [Array]
  def genre_form
    doc.xpath('.//controlaccess/genreform')
       .map { |node| node.text.try(:strip) }
       .uniq
  end

  # @return [String]
  def link_url
    doc.at_xpath('/ead/eadheader/eadid/@url').try(:text).try(:strip)
  end

  # Returns truthy solr boolean value if record is penn record, otherwise returns a solr falsey value.
  #
  # @return [Boolean]
  def upenn_record?
    repository.split(':')[0] == 'University of Pennsylvania'
  end

  # Determine if we will show any "Online Content" links
  # @return [Boolean]
  def online_content?
    # if dao node found anywhere in dsc - this handles deep nesting of <c*> nodes
    doc.xpath('/ead/archdesc/dsc//dao').try(:any?)
  end

  private

  # @todo move to Indexers::Record?
  # extract years from val based on range and date finding regex YEARS_REGEX
  # @param [String] val
  # @return [Array]
  def to_years_array(val)
    matches = val.scan YEARS_REGEX
    return [] if matches.empty?

    matches.sum([]) { |years|
      if years.compact.length == 1
        [years[0].to_i]
      elsif years[1] == '9999'
        (years[0].to_i..Time.zone.now.year).to_a
      else
        (years[0]..years[1]).to_a.map(&:to_i)
      end
    }.uniq
  end

  # Provide additional EAD specification validations, for example validating EAD XML namespace
  # @raises StandardError
  # @return [nil]
  def validate_ead_spec!
    return unless doc.namespaces['xmlns']&.include?('http://ead3.archivists.org/schema/')

    raise ValidationError, 'EAD3 spec not supported'
  end
end
