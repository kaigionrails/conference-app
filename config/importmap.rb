# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "service_worker_installer", preload: true
pin "stimulus-dropdown", to: "https://cdn.jsdelivr.net/npm/stimulus-dropdown@2.1.0/dist/stimulus-dropdown.mjs"
pin "stimulus-use", to: "https://cdn.jsdelivr.net/npm/stimulus-use@0.52.2/dist/index.js"
pin "@rails/request.js", to: "https://cdn.jsdelivr.net/npm/@rails/request.js@0.0.9/dist/requestjs.min.js"
pin "trix", to: "https://cdn.jsdelivr.net/npm/trix@2.0.7/dist/trix.esm.min.js"
pin "@rails/actiontext", to: "actiontext.js"
pin "qrcode", to: "https://ga.jspm.io/npm:qrcode@1.5.3/lib/browser.js"
pin "dijkstrajs", to: "https://ga.jspm.io/npm:dijkstrajs@1.0.3/dijkstra.js"
pin "encode-utf8", to: "https://ga.jspm.io/npm:encode-utf8@1.0.3/index.js"
pin "jose", to: "https://cdn.jsdelivr.net/npm/jose@4.15.4/dist/browser/index.js"
pin "stimulus-lightbox", to: "https://cdn.jsdelivr.net/npm/stimulus-lightbox@3.2.0/dist/stimulus-lightbox.mjs"
pin "lightgallery", to: "https://cdn.jsdelivr.net/npm/lightgallery@2.7.2/lightgallery.es5.js"
