# frozen_string_literal: true

require 'csv'

namespace :tools do
  desc 'Index sample data'
  task index_sample_data: :environment do
    status = Open3.capture2e "curl -sX POST '#{ENV.fetch('SOLR_URL')}/update/json?commit=true' --data-binary @data/solr_json/sample.json -H 'Content-type:application/json'"
    puts status.join
  end

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
    # Read CSV data
    endpoint_csv = Rails.root.join('data/endpoints.csv')
    endpoint_data = CSV.parse(File.read(endpoint_csv), headers: true, strip: true)

    # Get current inventory for diffing later
    current_endpoint_slugs = Endpoint.all.pluck(:slug)
    puts "Current endpoint slugs: #{current_endpoint_slugs.join(' | ')}"

    # Get or build objects
    endpoints = endpoint_data&.map do |endpoint_info|
      slug = endpoint_info['slug']
      unless endpoint_info['type'].in? Endpoint::TYPES
        puts "Invalid type set for #{slug}: #{endpoint_info['type']}"
        next
      end
      if Endpoint.exists? slug: slug
        puts "Endpoint exists for #{slug}, will update."
        endpoint = Endpoint.find_by slug: slug
        endpoint.public_contacts = Array.wrap(endpoint_info['public_contact'])
        endpoint.tech_contacts = Array.wrap(endpoint_info['tech_contact'])
      else
        puts "Will create new endpoint #{slug}."
        endpoint = Endpoint.new(
          {
            slug:,
            public_contacts: Array.wrap(endpoint_info['public_contact']),
            tech_contacts: Array.wrap(endpoint_info['tech_contact'])
          }
        )
      end
      endpoint.harvest_config['type'] = endpoint_info['type']
      endpoint.harvest_config['repository_id'] = endpoint_info['aspace_id'] if endpoint_info['aspace_id'].present?
      endpoint.harvest_config['url'] = endpoint_info['index_url'] if endpoint_info['index_url'].present?
      endpoint
    end

    # Save and report
    endpoints&.each do |ep|
      if ep.save
        puts "#{ep.slug} saved OK."
      else
        puts "Problem saving #{ep.slug}: #{ep.errors.as_json}"
      end
    end

    # Process removals
    new_endpoint_slugs = endpoints.map(&:slug)
    diff = current_endpoint_slugs - new_endpoint_slugs
    if diff.any?
      puts "These endpoints were removed and will be deleted: #{diff.join(' | ')}"
      diff.each do |endpoint_slug_to_remove|
        rip_endpoint = Endpoint.find_by slug: endpoint_slug_to_remove
        rip_endpoint.destroy
        puts "#{endpoint_slug_to_remove} removed. You might want to remove its records!"
      end
    end
  rescue CSV::MalformedCSVError => e
    puts "Task aborted: problem parsing CSV on line #{e.line_number}"
  rescue Errno::ENOENT
    puts "Cannot read CSV file at #{endpoint_csv}."
  end
end
