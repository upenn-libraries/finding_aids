# frozen_string_literal: true

# Configuration to generate sitemap.
SitemapGenerator::Sitemap.default_host = Rails.application.config.default_host
SitemapGenerator::Sitemap.sitemaps_path = 'sitemap/'

SitemapGenerator::Sitemap.create do
  # Add repositories page
  add repositories_path, priority: 0.5, changefreq: 'weekly'

  # Add all record pages
  Blacklight.default_index.search(rows: 1_000_000, fl: 'id').docs.each do |record|
    add solr_document_path(record[:id]), priority: 0.5, changefreq: 'monthly'
  end
end
