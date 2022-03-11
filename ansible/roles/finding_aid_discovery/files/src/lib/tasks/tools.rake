# frozen_string_literal: true

require 'csv'

namespace :tools do
  desc 'Index sample data'
  task index_sample_data: :environment do
    status = Open3.capture2e "curl -sX POST '#{ENV['SOLR_URL']}/update/json?commit=true' --data-binary @data/solr_json/sample.json -H 'Content-type:application/json'"
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

  desc 'Sync index type endpoints'
  task sync_index_endpoints: :environment do
    # Read CSV data
    index_endpoint_csv = Rails.root.join('data/index_endpoints.csv')
    index_endpoint_data = CSV.parse(File.read(index_endpoint_csv), headers: true, strip: true)

    # Get current inventory for diffing later
    current_index_endpoint_slugs = Endpoint.index_type.pluck(:slug)
    puts "Current index endpoint slugs: #{current_index_endpoint_slugs.join(' | ')}"
    puts "Index type endpoints currently configured: #{current_index_endpoint_slugs.size}"

    # Get or build objects
    endpoints = index_endpoint_data&.map do |endpoint_info|
      slug = endpoint_info['slug']
      if Endpoint.index_type.exists? slug: slug
        puts "Endpoint exists for #{slug}, will update."
        endpoint = Endpoint.find_by slug: slug
        endpoint.public_contacts = Array.wrap(endpoint_info['public_contact'])
        endpoint.tech_contacts = Array.wrap(endpoint_info['tech_contact'])
        endpoint.harvest_config = { type: 'index', url: endpoint_info['url'] }
        endpoint
      else
        puts "Will create new endpoint #{slug}."
        Endpoint.new(
          {
            slug: slug,
            public_contacts: Array.wrap(endpoint_info['public_contact']),
            tech_contacts: Array.wrap(endpoint_info['tech_contact']),
            harvest_config: { type: 'index', url: endpoint_info['url'] }
          }
        )
      end
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
    new_index_endpoint_slugs = Endpoint.index_type.pluck(:slug)
    diff = current_index_endpoint_slugs - new_index_endpoint_slugs
    if diff.any?
      puts "These index endpoints were removed and will be deleted: #{diff.join(' | ')}"
      diff.each do |endpoint_slug_to_remove|
        rip_endpoint = Endpoint.find_by slug: endpoint_slug_to_remove
        rip_endpoint.destroy
        puts "#{endpoint_slug_to_remove} removed. You might want to remove its records!"
      end
    end
  rescue CSV::MalformedCSVError => e
    puts "Task aborted: problem parsing CSV on line #{e.line_number}"
  rescue Errno::ENOENT
    puts "Cannot read CSV file at #{index_endpoint_csv}."
  end

  desc 'Sync aspace type endpoints'
  task sync_aspace_endpoints: :environment do
    # Read CSV data
    aspace_endpoint_csv = Rails.root.join('data/aspace_endpoints.csv')
    aspace_endpoint_data = CSV.parse(File.read(aspace_endpoint_csv), headers: true, strip: true)

    # Get current inventory for diffing later
    current_aspace_endpoint_slugs = Endpoint.aspace_type.pluck(:slug)
    puts "Current aspace endpoint slugs: #{current_aspace_endpoint_slugs.join(' | ')}"
    puts "ASpace type endpoints currently configured: #{current_aspace_endpoint_slugs.size}"

    # Get or build objects
    endpoints = aspace_endpoint_data&.map do |endpoint_info|
      slug = endpoint_info['slug']
      if Endpoint.aspace_type.exists? slug: slug
        puts "Endpoint exists for #{slug}, will update."
        endpoint = Endpoint.find_by slug: slug
        endpoint.public_contacts = Array.wrap(endpoint_info['public_contact'])
        endpoint.tech_contacts = Array.wrap(endpoint_info['tech_contact'])
        endpoint.harvest_config = { type: 'archives_space', repository_id: endpoint_info['repository_id'] }
        endpoint
      else
        puts "Will create new endpoint #{slug}."
        Endpoint.new(
          {
            slug: slug,
            public_contacts: Array.wrap(endpoint_info['public_contact']),
            tech_contacts: Array.wrap(endpoint_info['tech_contact']),
            harvest_config: { type: 'archives_space', repository_id: endpoint_info['repository_id'] }
          }
        )
      end
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
    new_aspace_endpoint_slugs = Endpoint.aspace_type.pluck(:slug)
    diff = current_aspace_endpoint_slugs - new_aspace_endpoint_slugs
    if diff.any?
      puts "These aspace endpoints were removed and will be deleted: #{diff.join(' | ')}"
      diff.each do |endpoint_slug_to_remove|
        rip_endpoint = Endpoint.find_by slug: endpoint_slug_to_remove
        rip_endpoint.destroy
        puts "#{endpoint_slug_to_remove} removed. You might want to remove its records!"
      end
    end
  rescue CSV::MalformedCSVError => e
    puts "Task aborted: problem parsing CSV on line #{e.line_number}"
  rescue Errno::ENOENT
    puts "Cannot read CSV file at #{aspace_endpoint_csv}."
  end
end
