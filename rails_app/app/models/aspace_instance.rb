# frozen_string_literal: true

# Represent an ArchiveSpace instance that we will harvest records from.
class ASpaceInstance < ApplicationRecord
  validates :slug, :base_url, :username, presence: true
  validates :slug, format: { with: /\A[a-z_]+\z/ }, uniqueness: true

  has_many :endpoints, dependent: :restrict_with_exception

  # def username
  #   # TODO: needs to be read in from docker secrets
  # end

  def password
    # TODO: needs to be read in from docker secrets
  end
end
