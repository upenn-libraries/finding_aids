# frozen_string_literal: true

# helper for pulling secrets from docker secrets store or environment
class SecretsService
  PERMITTED_SECRETS = %i[penn_aspace_api_username penn_aspace_api_password].freeze
  SECRET_STORE_PATH = '/run/secrets'

  class SecretsServiceError < StandardError; end

  # @param [Symbol, String] key
  # @param [String, NilClass] default
  # @return [String, NilClass]
  def self.lookup(key:, default: nil)
    raise SecretsServiceError, 'No secret key defined' if key.blank?
    raise SecretsServiceError, "Non-permitted secret key provided: #{key}" unless key.to_sym.in? PERMITTED_SECRETS

    secret_file_path = File.join SECRET_STORE_PATH, key.to_s
    if File.exist? secret_file_path
      File.read(secret_file_path).strip
    else
      ENV.fetch key, default # TODO: raise exception if secret not found in ENV?
    end
  end
end
