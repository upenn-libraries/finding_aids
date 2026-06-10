# frozen_string_literal: true

# Loads and caches homepage data from YAML files.
# Separated from HomepageHelper so the helper owns only URL/facet concerns.
class HomepageData
  COLLECTION_GUIDES_PATH = Rails.root.join('data/collection_guides.yml')
  REPOSITORIES_PATH = Rails.root.join('data/repositories.yml')

  # Load all collection guides from YAML.
  #
  # @return [Array<OpenStruct>] guide objects with +name+, +collection+, +identifier+
  def collection_guides
    load(COLLECTION_GUIDES_PATH, %w[name collection identifier])
  end

  # Load all repositories from YAML.
  #
  # @return [Array<OpenStruct>] repo objects with +name+, +slug+, +count+, +lat+, +lng+
  def repositories
    load(REPOSITORIES_PATH, %w[name slug count lat lng])
  end

  private

  # Load and cache a YAML file, wrapping each entry in OpenStruct for
  # named accessor methods instead of raw hash keys.
  #
  # @param path [Pathname] absolute path to the YAML file
  # @param expected_keys [Array<String>] keys that must be present in each entry
  # @return [Array<OpenStruct>] parsed entries as OpenStruct objects
  def load(path, expected_keys)
    @cache ||= {}
    @cache[path] ||= begin
      raise Errno::ENOENT, path unless path.exist?

      entries = YAML.load_file(path)
      entries.map { |entry| OpenStruct.new(entry.slice(*expected_keys)) }
    end
  rescue Errno::ENOENT, Psych::SyntaxError => e
    Rails.logger.warn "Homepage data file missing or malformed: #{path} — #{e.message}"
    @cache[path] = []
  end
end
