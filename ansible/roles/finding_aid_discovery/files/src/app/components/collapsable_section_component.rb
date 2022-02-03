class CollapsableSectionComponent < ViewComponent::Base
  renders_one :title
  renders_one :body

  def initialize(id:)
    @collapsable_id = id
  end
end
