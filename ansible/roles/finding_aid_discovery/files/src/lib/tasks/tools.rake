require 'csv'

namespace :tools do
  desc 'Index sample data'
  task index_sample_data: :environment do
    status = Open3.capture2e "curl -sX POST '#{ENV['SOLR_URL']}/update/json?commit=true' --data-binary @data/solr_json/sample.json -H 'Content-type:application/json'"
    puts status.join
  end

  desc 'Sync index type endpoints'
  task sync_index_endpoints: :environment do
    # Read CSV data
    index_endpoint_csv = File.join Rails.root, 'data', 'index_endpoints.csv'
    index_endpoint_data = CSV.parse(File.read(index_endpoint_csv), headers: true)

    # Get current inventory for diffing later
    current_index_endpoint_slugs = Endpoint.index_type.pluck(:slug)
    puts "Current index endpoint slugs: #{current_index_endpoint_slugs.join(' | ')}"
    puts "Index type Endpoints currently configured: #{current_index_endpoint_slugs.size}"

    # Get or build objects
    endpoints = index_endpoint_data&.map do |endpoint_info|
      slug = endpoint_info['slug']&.strip
      if Endpoint.index_type.exists? slug: slug
        puts "Endpoint exists for #{slug}, will update."
        Endpoint.find_by slug: slug
      else
        puts "Will create new endpoint #{slug}."
        Endpoint.new({
                        slug: slug,
                        public_contacts: Array.wrap(endpoint_info['public_contact']&.strip),
                        tech_contacts: Array.wrap(endpoint_info['tech_contact']&.strip),
                        harvest_config: { type: 'index',
                                          url: endpoint_info['url']&.strip }
                      })
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
        puts "#{rip_endpoint} removed. You might want to remove its records!"
      end
    end
  rescue CSV::MalformedCSVError => e
    puts "Task aborted: problem parsing CSV on line #{e.line_number}"
  rescue Errno::ENOENT
    puts "Cannot read CSV file at #{index_endpoint_csv}."
  end
end
