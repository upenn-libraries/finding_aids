# frozen_string_literal: true

# Controller for static pages `about` and `how-to-use`
class StaticPagesController < ApplicationController
  before_action :load_regional_repos, only: :about

  def about; end
end
