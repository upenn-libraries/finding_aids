# frozen_string_literal: true

namespace :geocode do
  desc 'Rebuild geocoding cache file'
  task rebuild: :environment do
    puts Rainbow('Rebuilding geocoder file - all existing data will be lost').bold.red
    cache = Geocoding::Cache.new
    service = Geocoding::Service.new cache: cache
    addresses = RepositoryQueries.addresses.select { |_, address| address.present? }

    entries = service.run!(addresses) do |name, result|
      puts Rainbow('─' * 60).bright.black
      puts Rainbow("Processing: #{name}").bold.yellow

      if result.success?
        puts Rainbow("  ✓ #{result.lat}, #{result.lng}").green
      else
        puts Rainbow('  ✗ No results or API error').red
      end
    end

    puts Rainbow("\n✅ Cache built with #{entries} entries and saved to #{cache.path}\n").bold.green
  end

  desc 'Update geocoding cache'
  # Add any new entries to cache file
  task update: :environment do
    puts Rainbow('Updating geocoder file - adding new entries').bold.red
    cache = Geocoding::Cache.new
    service = Geocoding::Service.new cache: cache
    addresses = RepositoryQueries.addresses.select { |_, address| address.present? }
    added = 0

    addresses.each do |name, address|
      next if cache[name].present?

      puts Rainbow('─' * 60).bright.black
      puts Rainbow("Processing new entry: #{name}").bold.yellow

      result = service.geocode(address)
      if result.success?
        added += 1
        puts Rainbow("  ✓ #{result.lat}, #{result.lng}").green
      else
        puts Rainbow('  ✗ No results or API error').red
      end
    end

    if added.positive?
      puts Rainbow("\n✅ Cache updated with #{added} entries and saved to #{cache.path}\n").bold.green
    else
      puts Rainbow("\n✓ No updates needed\n").bold.cyan
    end
  end
end
