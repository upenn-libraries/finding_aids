# frozen_string_literal: true

# Footer component using Penn Libraries design system footer web components.
class FooterComponent < Blacklight::Component
  delegate :current_user, to: :helpers
end
