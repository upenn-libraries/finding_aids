# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin 'application', preload: true
# bundled bootstrap package that includes popper peer dependency
pin '@popperjs/core', to: 'https://ga.jspm.io/npm:@popperjs/core@2.11.8/dist/umd/popper.min.js'
pin 'bootstrap', to: 'https://ga.jspm.io/npm:bootstrap@5.3.8/dist/js/bootstrap.js'
pin '@hotwired/stimulus', to: 'https://ga.jspm.io/npm:@hotwired/stimulus@3.2.2/dist/stimulus.js'
pin 'initialize', preload: true
pin 'requests', preload: true
pin_all_from 'app/javascript/controllers', under: 'controllers'
