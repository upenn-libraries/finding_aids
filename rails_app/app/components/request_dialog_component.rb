# frozen_string_literal: true

# Renders the multi-step request modal (`<dialog>`) and the fixed bottom bar
# that surfaces selected inventory items. Driven by the `request` Stimulus
# controller, which reads checkbox state from the inventory table and walks
# the user through the requesting flow.
class RequestDialogComponent < ViewComponent::Base
  # @param repository [String] holding institution name, shown under "Held at"
  def initialize(repository:)
    @repository = repository_info(repository_name: repository)
  end

  private

  def repository_info(repository_name: repository_name)
    Settings.aeon.locations.find { |loc| loc[:label] == repository_name }
  end
end
