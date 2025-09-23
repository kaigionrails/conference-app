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
pin "trix", to: "https://cdn.jsdelivr.net/npm/trix@2.1.15/dist/trix.esm.min.js"
pin "@rails/actiontext", to: "actiontext.js"
pin "qrcode", to: "https://ga.jspm.io/npm:qrcode@1.5.4/lib/browser.js"
pin "dijkstrajs", to: "https://ga.jspm.io/npm:dijkstrajs@1.0.3/dijkstra.js"
pin "jose", to: "https://cdn.jsdelivr.net/npm/jose@5.9.3/+esm"
pin "photoswipe", to: "https://cdn.jsdelivr.net/npm/photoswipe@5.4.4/dist/photoswipe.esm.min.js"
pin "photoswipe/lightbox", to: "https://cdn.jsdelivr.net/npm/photoswipe@5.4.4/dist/photoswipe-lightbox.esm.min.js"
pin "hls.js", to: "https://cdn.jsdelivr.net/npm/hls.js@1.5.17/+esm"
pin "locales"

# for i18n-js
pin "i18n-js", to: "https://ga.jspm.io/npm:i18n-js@4.5.1/dist/import/index.js"
pin "bignumber.js", to: "https://ga.jspm.io/npm:bignumber.js@9.3.1/bignumber.mjs"
pin "lodash/camelCase", to: "https://ga.jspm.io/npm:lodash@4.17.21/camelCase.js"
pin "lodash/get", to: "https://ga.jspm.io/npm:lodash@4.17.21/get.js"
pin "lodash/has", to: "https://ga.jspm.io/npm:lodash@4.17.21/has.js"
pin "lodash/merge", to: "https://ga.jspm.io/npm:lodash@4.17.21/merge.js"
pin "lodash/range", to: "https://ga.jspm.io/npm:lodash@4.17.21/range.js"
pin "lodash/repeat", to: "https://ga.jspm.io/npm:lodash@4.17.21/repeat.js"
pin "lodash/sortBy", to: "https://ga.jspm.io/npm:lodash@4.17.21/sortBy.js"
pin "lodash/uniq", to: "https://ga.jspm.io/npm:lodash@4.17.21/uniq.js"
pin "lodash/zipObject", to: "https://ga.jspm.io/npm:lodash@4.17.21/zipObject.js"
pin "make-plural", to: "https://ga.jspm.io/npm:make-plural@7.4.0/plurals.mjs"
