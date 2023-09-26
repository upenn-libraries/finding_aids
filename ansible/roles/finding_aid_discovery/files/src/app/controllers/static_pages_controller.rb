class StaticPagesController < ApplicationController
  def about
    render 'static_pages/about'
  end

  def how_to_use
    render 'static_pages/how_to_use'
  end
end