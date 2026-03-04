# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# external lightweight QR code decoder library (ESM build via jsDelivr)
pin "jsqr", to: "https://cdn.jsdelivr.net/npm/jsqr@1.4.0/+esm"
