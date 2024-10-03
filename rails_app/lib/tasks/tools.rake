# frozen_string_literal: true

require 'csv'

namespace :tools do
  desc 'Harvest selected endpoints'
  task harvest_from: :environment do
    abort(Rainbow('Incorrect arguments. Pass endpoints=first,second,third').red) if ENV['endpoints'].blank?

    slugs = ENV['endpoints'].split(',')
    endpoints = if slugs.size == 1 && slugs.first.eql?('all')
                  Endpoint.all
                else
                  Endpoint.where(slug: slugs)
                end

    puts Rainbow("Harvesting from #{endpoints.count} endpoints").green

    endpoints.each do |ep|
      print "Harvesting #{ep.slug} ... "

      # Skip localhost endpoints
      if ep.url&.include? '127.0.0.1'
        puts Rainbow("Skipping because it's @ #{ep.url}").cyan
        next
      end

      begin
        HarvestingService.new(ep).harvest
        ep.reload
        status_color = {
          Endpoint::LastHarvest::PARTIAL => :yellow,
          Endpoint::LastHarvest::COMPLETE => :green,
          Endpoint::LastHarvest::FAILED => :red
        }[ep.last_harvest.status]
        puts Rainbow(ep.last_harvest.status.titlecase).color(status_color)
      rescue StandardError => e
        puts Rainbow("Error\n    #{e.message}").red
        puts "    #{e.backtrace.join("\n    ")}"
      end
    end
    puts Rainbow('All done!').green
  end

  desc 'Sync all endpoints'
  task sync_endpoints: :environment do
    # Hard coding UPenn ASpace instance for now. We'll move away from this soon.
    ASpaceInstance.find_or_create_by(slug: 'university_of_pennsylvania') do |instance|
      instance.base_url = 'https://upennstaff.as.atlas-sys.com'
      instance.username = SecretsService.lookup(key: 'penn_aspace_api_username')
    end
    Endpoint.sync_from_csv(Rails.root.join('data/endpoints.csv'))
  end

  desc 'Create appropriate robots.txt for the environment'
  task robotstxt: :environment do
    prod_robots = <<~PROD
      User-agent: *
      Disallow: /admin
      Disallow: /records/facet/
      Disallow: /records*f%5B
      Disallow: /records*f[
      Sitemap: https://findingaids.library.upenn.edu/sitemap/sitemap.xml.gz
    PROD

    non_prod_robots = <<~NONPROD
      User-agent: *
      Disallow: /
    NONPROD

    robotstxt = Rails.env.production? ? prod_robots : non_prod_robots

    Rails.public_path.join('robots.txt').write(robotstxt)
  end

  desc 'Generate a sitemap if its missing'
  task ensure_sitemap: :environment do
    sitemap_path = Rails.public_path.join('sitemap/sitemap.xml.gz')
    Rake::Task['sitemap:create'].invoke unless File.exist?(sitemap_path)
  end
end
