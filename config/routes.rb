Rails.application.routes.draw do
  # legacy underscored path used prior to hyphenated URLs; redirect so old
  # bookmarks continue to work and to make functional tests easier.  these
  # redirects don't need helpers, so we explicitly disable naming to avoid
  # collisions with the real portal route below.
  # legacy underscored path used prior to hyphenated URLs; redirect so old
  # bookmarks continue to work and to make functional tests easier.  these
  # redirects don't need helpers, so we explicitly disable naming to avoid
  # collisions with the real portal route below.  ensure query parameters are
  # forwarded so that links like /attendee_portal?code=XYZ still reach the
  # login logic.
  get "attendee_portal/*any" => redirect { |params, req|
    query = req.query_string.present? ? "?#{req.query_string}" : ""
    "/attendee-portal/#{params[:any]}#{query}"
  }, as: nil
  get "attendee_portal" => redirect { |params, req|
    query = req.query_string.present? ? "?#{req.query_string}" : ""
    "/attendee-portal#{query}"
  }, as: nil

  get "attendee-portal/" => "attendee_portal#index", as: :attendee_portal
  get "attendee-portal/contact" => "attendee_portal#contact", as: :attendee_portal_contact
  # use POST for sending messages; the UI submits a form rather than
  # navigating, so we don’t need a GET action here.
  post "attendee-portal/contact" => "attendee_portal#create_new_message"
  # legacy helper kept for compatibility; remains GET in case anyone links
  # directly, but the form no longer uses this.
  get "attendee-portal/contact-new" => "attendee_portal#create_new_message", as: :attendee_portal_contact_new
  get "attendee-portal/qr-code" => "attendee_portal#qr_code", as: :attendee_portal_qr_code
  get "attendee-portal/waiver" => "attendee_portal#waiver", as: :attendee_portal_waiver
  patch "attendee-portal/waiver" => "attendee_portal#sign_waiver"
  patch "attendee-portal/" => "attendee_portal#update"  # profile edits should POST back here

  # simple portal login using attendee code (no user account required)
  get  "attendee-portal/login"  => "attendee_portal#login",  as: :attendee_portal_login
  post "attendee-portal/login"  => "attendee_portal#authenticate"
  delete "attendee-portal/logout" => "attendee_portal#logout", as: :attendee_portal_logout
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  #
  get "events/" => "events#index", as: :events

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Routes for authentication via OmniAuth
  get "/auth/:provider/callback", to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout
  # also handle simple GET for users without JS; perform same action
  # (session destruction is idempotent and doesn’t require CSRF protection)
  get "/logout", to: "sessions#destroy"

  # dynamic SVG icons with configurable color (?color=hex-or-name)
  get "icons/menu-open", to: "icons#menu_open", as: :icon_menu_open

  # a simple root for now
  root "home#index"

  # QR code generator/decoder
  resource :qr_code, only: [ :new, :create ] do
    collection do
      get :decode
    end
  end

  # public link for attendee QR pages (used by emails)
  get "/qrcode/:code", to: "qr_codes#show", as: :public_qr_code

  # we no longer expose a global /events index; everything is scoped to an
  # organisation. any remaining references to non-nested event routes should
  # be removed or updated accordingly.

  # public apply page using only the alphanumeric token (no org context)
  get "/:apply_token/apply", to: "events#apply_by_token", as: :public_apply_event
  post "/:apply_token/apply", to: "events#apply_create"

  # organisations with nested events
  resources :organisations, path: "org" do
    collection do
      get :setting
      get :admin
    end

    # introduce a member dashboard route that delegates to a dedicated
    # controller so that views may live under app/views/organisations/dashboard
    member do
      get :dashboard, to: "organisations/dashboard#index"
      # route for organisation dashboard events list
      get "dashboard/events", to: "organisations/dashboard/events#index", as: :dashboard_events
      get "dashboard/events/attendees", to: "organisations/dashboard/events#attendees", as: :dashboard_events_attendees
    end

    resources :events do
      member do
        get "attendees", to: "events#attendees"
        post "send_qr_codes", to: "organisations/dashboard/events#send_qr_codes"

        # show a specific attendee linked from the events list
        # view a specific attendee for this event
        get "attendee/:attendee_id", to: "events#attendee", as: :attendee
        # editing existing attendee
        get "attendee/:attendee_id/edit", to: "events#edit_attendee", as: :edit_attendee
        patch "attendee/:attendee_id", to: "events#update_attendee"

        # view specific attendee waiver
        get "attendee/:attendee_id/waiver", to: "events#attendee_waiver", as: :attendee_waiver
        delete "attendee/:attendee_id/waiver", to: "events#destroy_attendee_waiver", as: :destroy_attendee_waiver

        # sign‑up form and submission
        get "apply", to: "events#apply"
        post "apply", to: "events#apply_create"
        get "actions/sign-in",  to: "events#sign_in"
        get "actions/sign-out", to: "events#sign_out"
        get "actions/get-info", to: "events#get_info"
        post "actions/scan", to: "events#scan", as: :scan
      end
    end
  end
end
