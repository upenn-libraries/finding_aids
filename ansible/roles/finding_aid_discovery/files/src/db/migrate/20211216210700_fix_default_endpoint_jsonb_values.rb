# Fix error from previous migration where default values for JSONB fields were set to String
# https://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#changes-with-json-jsonb-serialization
class FixDefaultEndpointJsonbValues < ActiveRecord::Migration[6.1]
  def change
    change_column_default :endpoints, :harvest_config, from: '{}', to: {}
    change_column_default :endpoints, :last_harvest_results, from: '{}', to: {}
  end
end
