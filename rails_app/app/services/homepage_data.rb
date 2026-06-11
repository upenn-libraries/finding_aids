# frozen_string_literal: true

# Loads and caches homepage data from YAML files.
# Uses a class-level cache so YAML is parsed once per process start,
# not once per request.
class HomepageData
  COLLECTION_GUIDES_PATH = Rails.root.join('data/collection_guides.yml')
  REPOSITORIES_PATH = Rails.root.join('data/repositories.yml')

  CollectionGuide = Data.define(:name, :collection)
  Repository = Data.define(:name, :slug, :count, :lat, :lng)

  # Load all collection guides from YAML.
  #
  # @return [Array<CollectionGuide>] guide objects with +name+, +collection+
  def collection_guides
    load(COLLECTION_GUIDES_PATH, CollectionGuide)
  end

  # Load all repositories from YAML.
  #
  # @return [Array<Repository>] repo objects with +name+, +slug+, +count+, +lat+, +lng+
  def repositories
    load(REPOSITORIES_PATH, Repository)
  end

  # Class-level cache so YAML is parsed once per process, not per request.
  @cache = {}
  class << self
    attr_reader :cache
  end

  private

  # Load and cache a YAML file, wrapping each entry in the given Data class.
  #
  # @param path [Pathname] absolute path to the YAML file
  # @param struct_class [Class] Data.define class whose members match the YAML keys
  # @return [Array] parsed entries as Data objects
  def load(path, struct_class)
    self.class.cache[path] ||= parse_yaml(path).map { |entry| build_entry(entry, struct_class) }
  rescue Errno::ENOENT, Psych::SyntaxError => e
    Rails.logger.warn "Homepage data file missing or malformed: #{path} — #{e.message}"
    self.class.cache[path] || []
  end

  def parse_yaml(path)
    YAML.safe_load_file(path, permitted_classes: [], symbolize_names: true)
  end

  def build_entry(entry, struct_class)
    keys = struct_class.members
    struct_class.new(**entry.slice(*keys))
  end
end
