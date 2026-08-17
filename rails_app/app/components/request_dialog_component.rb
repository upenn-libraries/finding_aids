# frozen_string_literal: true

# Renders the multi-step request modal (`<dialog>`) and the fixed bottom bar
# that surfaces selected inventory items. Driven by the `request` Stimulus
# controller, which reads checkbox state from the inventory table and walks
# the user through the requesting flow.
class RequestDialogComponent < ViewComponent::Base
  # @param repository [String] holding institution name
  def initialize(repository:)
    @repository = Settings.aeon.locations.find { |loc| loc[:label] == repository }
  end
end
