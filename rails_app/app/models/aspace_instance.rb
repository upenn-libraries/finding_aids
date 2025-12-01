# frozen_string_literal: true

# Represent an ArchiveSpace instance that we will harvest records from.
class ASpaceInstance < ApplicationRecord
  # Use a constant to handle a default throttle rather than a DB default so that it can be adjusted without
  # having to do a migration
  DEFAULT_THROTTLE = 0.5
  THROTTLE_RANGE = 0.1..2

  validates :harvest_throttle, numericality: { in: THROTTLE_RANGE }
  validates :slug, :base_url, presence: true
  validates :slug, format: { with: /\A[a-z_]+\z/ }, length: { maximum: 20 }, uniqueness: true

  has_many :endpoints, dependent: :restrict_with_exception

  # Docker secrets key must match slug + "_aspace_username"
  def username
    DockerSecrets.lookup(:"#{slug}_aspace_username")
  end

  # Docker secrets key must match slug + "_aspace_password"
  def password
    DockerSecrets.lookup(:"#{slug}_aspace_password")
  end

  def harvest_throttle
    throttle || DEFAULT_THROTTLE
  end
end
