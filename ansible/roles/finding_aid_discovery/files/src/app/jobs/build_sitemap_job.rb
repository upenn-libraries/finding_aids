# frozen_string_literal: true

# Job to build sitemap.
class BuildSitemapJob < ApplicationJob
  queue_as :default

  # Using sitemap_generator gem to generate sitemap.
  def perform
    SitemapGenerator::Interpreter.run(verbose: false)
  end
end