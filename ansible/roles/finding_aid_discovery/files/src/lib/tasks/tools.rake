namespace :tools do
  desc 'Index sample data'
  task :index_sample_data do
    status = Open3.capture2e "curl -sX POST '#{ENV['SOLR_URL']}/update/json?commit=true' --data-binary @data/solr_json/sample.json -H 'Content-type:application/json'"
    puts status.join
  end
end
