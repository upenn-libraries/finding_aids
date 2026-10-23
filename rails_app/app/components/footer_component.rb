# frozen_string_literal: true

# Footer component using Penn Libraries design system footer web components.
class FooterComponent < Blacklight::Component
  attr_reader :user

  def initialize(user: nil)
    @user = user
  end
end
