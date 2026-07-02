# frozen_string_literal: true

require 'csv'

namespace :geocode do
  desc 'List repository geocoding status'
  task status: :environment do
    cache = Geocoding::Cache.new
    cache.load
    addresses = RepositoryQueries.addresses

    puts Rainbow("\n📍 Repository Geocoding Status\n").bold.cyan
    puts Rainbow('=' * 60).cyan

    addresses.each do |name, address|
      entry = cache.load[name]
      status = if entry&.dig(:lat)
                 Rainbow('✓ CACHED').green
               elsif address.blank?
                 Rainbow('⚠ NO ADDRESS').yellow
               elsif entry&.dig(:_failed)
                 Rainbow('✗ FAILED').red
               else
                 Rainbow('○ NEEDS GEOCODING').red
               end

      puts "\n#{Rainbow(name).bold}"
      puts "  Address: #{address || 'N/A'}"
      puts "  Status:  #{status}"
      puts "  Coords:  #{entry[:lat]}, #{entry[:lng]}" if entry&.dig(:lat)
    end

    total = addresses.size
    cached = addresses.count { |name, _| cache.load[name]&.dig(:lat) }
    puts "\n#{Rainbow('=' * 60).cyan}"
    puts Rainbow("Summary: #{cached}/#{total} repositories geocoded\n").bold
  end

  desc 'Run geocoding with interactive disambiguation'
  task refresh: :environment do
    cache = Geocoding::Cache.new
    cache.load
    service = Geocoding::Service.new(cache: cache)
    non_interactive = ENV['NONINTERACTIVE'] || ENV['noninteractive']

    puts Rainbow("\n🚀 Starting geocoding refresh\n").bold.green
    puts Rainbow("Using #{Geocoder.config.lookup} API").cyan
    puts Rainbow("Mode: #{non_interactive ? 'non-interactive (auto-first)' : 'interactive'}\n").cyan

    updated = service.refresh!(RepositoryQueries.addresses) do |name, status, lat, lng|
      puts Rainbow('─' * 60).bright.black
      puts Rainbow("Processing: #{name}").bold.yellow

      if status == :ok
        puts Rainbow("  ✓ #{lat}, #{lng}").green
      elsif status == :failed
        puts Rainbow('  ✗ No results or API error').red
      end
    end

    if updated.positive?
      puts Rainbow("\n✅ Cache updated and saved to #{Geocoding::Cache::CACHEFILE}\n").bold.green
    else
      puts Rainbow("\n✓ No updates needed\n").bold.cyan
    end
  end

  desc 'Clear geocoding cache'
  task clear: :environment do
    Geocoding::Cache.new.clear!
    puts Rainbow('✓ Cleared geocoder cache').green
  rescue Errno::ENOENT
    puts Rainbow('No cache file to clear').yellow
  end

  desc 'Show collection counts per repository (from Solr)'
  task counts: :environment do
    repos = RepositoryQueries.facet_counts

    puts Rainbow("\n📊 Collection Counts by Repository\n").bold.cyan
    puts Rainbow('=' * 60).cyan

    repos.each do |repo|
      puts "#{Rainbow(repo[:name]).bold}: #{Rainbow(repo[:count].to_s).green} collections"
    end

    total = repos.sum { |r| r[:count] }
    puts Rainbow('=' * 60).cyan
    puts Rainbow("Total: #{total} collections\n").bold
  end
end

namespace :tools do
  desc 'Harvest selected endpoints'
  task harvest_from: :environment do
    abort(Rainbow('Incorrect arguments. Pass endpoints=first,second,third').red) if ENV['endpoints'].blank?
    abort(Rainbow('Please specify a limit greater than 0').red) if ENV['limit'].present? && ENV['limit'].to_i <= 0

    slugs = ENV['endpoints'].split(',')
    limit = ENV['limit'].presence&.to_i
    endpoints = if slugs.size == 1 && slugs.first.eql?('all')
                  Endpoint.all
                else
                  Endpoint.where(slug: slugs)
                end

    puts Rainbow("Harvesting from #{endpoints.count} endpoints").green

    endpoints.each do |ep|
      unless ep.active?
        puts Rainbow("Endpoint #{ep.slug} is inactive.").yellow
        next
      end

      print "Harvesting #{ep.slug} ... "

      if ep.webpage_url&.include? '127.0.0.1'
        puts Rainbow("Skipping because it's @ #{ep.webpage_url}").cyan
        next
      end

      begin
        HarvestingService.new(ep, limit: limit).harvest
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
