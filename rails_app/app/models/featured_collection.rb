# frozen_string_literal: true

# Featured collections shown on the homepage. Staff create and delete these via the admin UI.
class FeaturedCollection < ApplicationRecord
  validates :record_id, uniqueness: true, presence: true
end
