# frozen_string_literal: true

# Represent an ArchiveSpace instance that we will harvest records from.
class ASpaceInstance < ApplicationRecord
  validates :slug, :base_url, presence: true
  validates :slug, format: { with: /\A[a-z_]+\z/ }, uniqueness: true

  has_many :endpoints, dependent: :restrict_with_exception

  # Docker secrets key must match slug + "_aspace_username"
  def username
    DockerSecrets.lookup(:"#{slug}_aspace_username")
  end

  # Docker secrets key must match slug + "_aspace_password"
  def password
    DockerSecrets.lookup(:"#{slug}_aspace_password")
  end
end
