# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin 'application', preload: true
pin 'jquery', to: 'jquery3.min.js', preload: true
pin 'jquery_ujs', to: 'jquery_ujs.js', preload: true
# bundled bootstrap package that includes popper peer dependency
pin 'bootstrap', to: 'https://cdn.jsdelivr.net/npm/bootstrap@4.6.1/dist/js/bootstrap.bundle.min.js', preload: true
