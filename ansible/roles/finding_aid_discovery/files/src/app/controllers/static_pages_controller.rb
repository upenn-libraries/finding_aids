# frozen_string_literal: true

# Controller for static pages `about` and `how-to-use`
class StaticPagesController < ApplicationController
  def about
    render 'static_pages/about'
  end

  def how_to_use
    render 'static_pages/how_to_use'
  end
end