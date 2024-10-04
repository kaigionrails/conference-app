# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "service_worker_installer", preload: true
pin "stimulus-dropdown", to: "https://cdn.jsdelivr.net/npm/stimulus-dropdown@2.1.0/dist/stimulus-dropdown.mjs"
pin "stimulus-use", to: "https://cdn.jsdelivr.net/npm/stimulus-use@0.52.2/dist/index.js"
pin "@rails/request.js", to: "https://cdn.jsdelivr.net/npm/@rails/request.js@0.0.11/dist/requestjs.min.js"
pin "trix", to: "https://cdn.jsdelivr.net/npm/trix@2.0.7/dist/trix.esm.min.js"
pin "@rails/actiontext", to: "actiontext.js"
pin "qrcode", to: "https://ga.jspm.io/npm:qrcode@1.5.4/lib/browser.js"
pin "dijkstrajs", to: "https://ga.jspm.io/npm:dijkstrajs@1.0.3/dijkstra.js"
pin "jose", to: "https://cdn.jsdelivr.net/npm/jose@5.0.0/+esm"
pin "photoswipe", to: "https://cdn.jsdelivr.net/npm/photoswipe@5.4.4/dist/photoswipe.esm.min.js"
pin "photoswipe/lightbox", to: "https://cdn.jsdelivr.net/npm/photoswipe@5.4.4/dist/photoswipe-lightbox.esm.min.js"
