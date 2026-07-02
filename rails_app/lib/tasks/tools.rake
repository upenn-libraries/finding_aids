# frozen_string_literal: true

require 'csv'
require 'yaml'
require 'geocoder'

# Helper module for geocoding rake tasks
module GeocodeTasks
  CACHEFILE = Rails.root.join('tmp/geocoder_cache.yml')

  # @return [Hash]
  def self.load_cache
    if File.exist?(CACHEFILE)
      YAML.safe_load_file(CACHEFILE, permitted_classes: [Symbol], aliases: true) || {}
    else
      {}
    end
  end

  # @param cache [Hash]
  def self.persist_cache(cache)
    FileUtils.mkdir_p(File.dirname(CACHEFILE))
    File.write(CACHEFILE, Psych.dump(cache))
  end
end

namespace :geocode do
  desc 'List repository geocoding status'
  task status: :environment do
    cache = GeocodeTasks.load_cache
    addresses = RepositoryQueries.addresses

    puts Rainbow("\n📍 Repository Geocoding Status\n").bold.cyan
    puts Rainbow('=' * 60).cyan

    addresses.each do |name, address|
      cached = cache[name]
      status = if cached&.dig(:lat)
                 Rainbow('✓ CACHED').green
               elsif address.blank?
                 Rainbow('⚠ NO ADDRESS').yellow
               else
                 Rainbow('○ NEEDS GEOCODING').red
               end

      puts "\n#{Rainbow(name).bold}"
      puts "  Address: #{address || 'N/A'}"
      puts "  Status:  #{status}"
      puts "  Coords:  #{cached[:lat]}, #{cached[:lng]}" if cached&.dig(:lat)
    end

    total = addresses.size
    cached_count = addresses.count { |name, _| cache[name]&.dig(:lat) }
    puts "\n#{Rainbow('=' * 60).cyan}"
    puts Rainbow("Summary: #{cached_count}/#{total} repositories geocoded\n").bold
  end

  desc 'Run geocoding with interactive disambiguation'
  task refresh: :environment do
    cache = GeocodeTasks.load_cache
    addresses = RepositoryQueries.addresses
    updated = false
    non_interactive = ENV['NONINTERACTIVE'] || ENV['noninteractive']

    puts Rainbow("\n🚀 Starting geocoding refresh\n").bold.green
    puts Rainbow("Using #{Geocoder.config.lookup} API").cyan
    puts Rainbow("Mode: #{non_interactive ? 'non-interactive (auto-first)' : 'interactive'}\n").cyan

    addresses.each do |name, address|
      next if address.blank?
      next if cache[name]&.dig(:lat) # Already cached

      clean_address = address.gsub(/\(.*?\)/, '').gsub(/,\s*,/, ',').strip

      puts "\n#{Rainbow('─' * 60).bright.black}"
      puts Rainbow("Processing: #{name}").bold.yellow
      puts Rainbow("  Address: #{clean_address}").white

      begin
        results = Geocoder.search(clean_address)
        sleep 1.1 # Nominatim rate limit: 1 request per second
      rescue StandardError => e
        puts Rainbow("  ✗ API Error: #{e.message}").red
        cache[name] = { lat: nil, lng: nil }
        updated = true
        next
      end

      if results.empty?
        puts Rainbow('  ✗ No results found').red
        cache[name] = { lat: nil, lng: nil }
        updated = true
        next
      end

      if results.size == 1
        best = results.first
        if best.coordinates.all?(&:present?)
          cache[name] = { lat: best.latitude, lng: best.longitude }
          puts Rainbow("  ✓ #{best.latitude}, #{best.longitude}").green
          puts "    #{best.address}"
        else
          puts Rainbow('  ✗ Invalid coordinates').red
        end
        updated = true
      else
        # Multiple results - interactive disambiguation
        puts Rainbow('  ⚠ Multiple results - please choose:').yellow
        results.first(5).each_with_index do |result, idx|
          coords = result.coordinates
          puts "  #{idx + 1}. #{coords&.join(', ')} - #{result.address}"
        end

        if non_interactive
          # Auto-select first result in non-interactive mode
          best = results.first
          cache[name] = { lat: best.latitude, lng: best.longitude }
          puts Rainbow("    ✓ Auto-selected (first): #{best.latitude}, #{best.longitude}").green
          updated = true
        else
          print "\n  Enter choice (1-#{results.first(5).length}), 's' to skip, 'n' for none: "
          choice = ($stdin.gets || '').chomp.downcase

          case choice
          when 's', 'skip'
            puts Rainbow('    Skipped').bright.black
          when 'n', 'none', ''
            cache[name] = { lat: nil, lng: nil }
            updated = true
            puts Rainbow('    Marked as not found').red
          else
            idx = choice.to_i - 1
            if idx >= 0 && idx < results.first(5).length
              best = results[idx]
              cache[name] = { lat: best.latitude, lng: best.longitude }
              puts Rainbow("    ✓ Selected: #{best.latitude}, #{best.longitude}").green
              updated = true
            else
              puts Rainbow('    Invalid choice, skipping').red
            end
          end
        end
      end
    end

    if updated
      GeocodeTasks.persist_cache(cache)
      puts Rainbow("\n✅ Cache updated and saved to #{GeocodeTasks::CACHEFILE}\n").bold.green
    else
      puts Rainbow("\n✓ No updates needed\n").bold.cyan
    end
  end

  desc 'Clear geocoding cache'
  task clear: :environment do
    if File.exist?(GeocodeTasks::CACHEFILE)
      File.delete(GeocodeTasks::CACHEFILE)
      puts Rainbow('✓ Cleared geocoder cache').green
    else
      puts Rainbow('No cache file to clear').yellow
    end
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

      # Skip localhost endpoints
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
