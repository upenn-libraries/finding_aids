# frozen_string_literal: true

module Catalog
  # Local component copied from Blacklight v9.0 to change start over link destination and styles,
  # as well as add a tooltip and aria tag.
  class StartOverButtonComponent < Blacklight::Component
    def call
      link_to helpers.render('shared/svgs/start_over'), helpers.root_path,
              class: 'catalog_startOverLink btn btn-light',
              aria: { label: t('blacklight.search.start_over') },
              data: { controller: 'tooltip', bs_title: t('blacklight.search.start_over') }
    end
  end
end
