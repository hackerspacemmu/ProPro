# Pin npm packages by running ./bin/importmap

pin 'application'
pin '@hotwired/turbo-rails', to: 'turbo.min.js'
pin '@hotwired/stimulus', to: 'stimulus.min.js'
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js'
pin_all_from 'app/javascript/controllers', under: 'controllers'
pin 'htmx.org', to: 'https://cdnjs.cloudflare.com/ajax/libs/htmx/1.9.10/htmx.min.js'
pin 'project_template_fields'
pin "sortablejs", to: "https://unpkg.com/sortablejs@1.15.0/modular/sortable.esm.js"
pin "turndown", to: "https://cdn.jsdelivr.net/npm/turndown@7.2.4/+esm"
pin "turndown-plugin-gfm", to: "https://cdn.jsdelivr.net/npm/turndown-plugin-gfm@1.0.2/+esm"