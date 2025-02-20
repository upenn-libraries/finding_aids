# frozen_string_literal: true

ActiveSupport::Reloader.to_prepare do
  Blacklight::Rendering::Pipeline.operations = [Blacklight::Rendering::HelperMethod,
                                                Blacklight::Rendering::LinkToFacet,
                                                Blacklight::Rendering::Microdata,
                                                JoinProcessor]
end
