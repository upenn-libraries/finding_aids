# frozen_string_literal: true

# Curated collection guides featured on the homepage. Staff manage these
# via the admin UI at /admin/featured_collections.
class FeaturedCollection < ApplicationRecord
  validates :title, :repository, presence: true
  validate :title_must_exist_for_repository

  private

  def title_must_exist_for_repository
    return if title.blank? || repository.blank?

    titles = RepositoryQueries.titles_by_repository[repository] || []
    errors.add(:title, 'is not a collection at the selected repository') unless titles.include?(title)
  end
end
