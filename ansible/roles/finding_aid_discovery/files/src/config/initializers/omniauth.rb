# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer, fields: [:email] if Rails.env.development?

  provider :saml, {
    sp_entity_id: ENV['SHIB_SP_ENTITY_ID'],
    idp_sso_service_url: 'https://idp.pennkey.upenn.edu/idp/profile/SAML2/Redirect/SSO', # POST service URL didn't work
    idp_cert_fingerprint: '04:33:79:81:4E:7C:B7:B3:FA:91:AB:91:E3:94:78:15:03:C9:14:EF',
    request_attributes: [], # don't explicitly request attributes, rely on IdP defaults
    attribute_statements: { # https://www.isc.upenn.edu/how-to/shibboleth-attributes-available-penn
                            uid: ['urn:oid:1.3.6.1.4.1.5923.1.1.1.6'], # pennkey@upenn.edu
                            email: ['urn:oid:0.9.2342.19200300.100.1.3'], # directory (or pennname@upenn.edu) email, unless blocked
                            first_name: ['urn:oid:2.5.4.42'], # givenName from directory, unless blocked
                            last_name: ['urn:oid:2.5.4.4'], # surname from directory, unless blocked
                            full_name: ['urn:oid:2.16.840.1.113730.3.1.241'] # computed from directory info
    },
    # see: https://github.com/SAML-Toolkits/ruby-saml#clock-drift for why this is needed and for GitLab's discussion
    # see: https://gitlab.com/gitlab-org/gitlab/-/issues/13653#note_491162899
    allowed_clock_drift: 2.second
  }
end
