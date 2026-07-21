# frozen_string_literal: true

# Renders the multi-step request modal (`<dialog>`) and the fixed bottom bar
# that surfaces selected inventory items. Driven by the `request` Stimulus
# controller, which reads checkbox state from the inventory table and walks
# the user through Review → Details → Auth → Confirm.
#
# The dialog markup mirrors the Philadelphia Area Archives mockup. The auth
# (log-in) step is included but may be removed pending the Atlas Systems fix
# called out in issue #312.
class RequestDialogComponent < ViewComponent::Base
  # @param repository [String] holding institution name, shown under "Held at"
  # @param aeon_url [String] Aeon login URL for the auth step link
  def initialize(repository:, aeon_url:)
    @repository = repository
    @aeon_url = aeon_url
  end
end
