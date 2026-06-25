# frozen_string_literal: true

# Curated collection guides featured on the homepage. Staff manage these
# via the admin UI at /admin/featured_collections.
class FeaturedCollection < ApplicationRecord
  validates :title, :repository, presence: true
  validate :title_must_exist_for_repository

  scope :active, -> { where(active: true).order(:position) }

  private

  def title_must_exist_for_repository
    return if title.blank? || repository.blank?

    titles = RepositoryQueries.titles_by_repository[repository] || []
    errors.add(:title, 'is not a collection at the selected repository') unless titles.include?(title)
  rescue StandardError => e
    Rails.logger.warn "FeaturedCollection: title validation skipped — #{e.class}: #{e.message}"
  end
end
