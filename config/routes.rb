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

  get "/auth/hackclub", as: :sign_in_hackclub

  get "landing/" => "home#unregistered", as: :landing
  get "landing/events" => "home#events", as: :landing_events

  get "events/:id/announcements" => "events#announcements", as: :event_announcements

  get "attendee-portal/" => "attendee_portal#index", as: :attendee_portal
  get "attendee-portal/contact" => "attendee_portal#contact", as: :attendee_portal_contact
  get "attendee-portal/gallery" => "attendee_portal#gallery", as: :attendee_portal_gallery
  get "attendee-portal/gallery/new" => "attendee_portal#new_photo", as: :new_attendee_photo
  post "attendee-portal/gallery/new" => "attendee_portal#new_photo"
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

  # Routes for passwordless email login
  get "/login", to: "sessions#new_email", as: :login
  post "/login", to: "sessions#create_email"
  get "/login/verify", to: "sessions#verify_email", as: :login_verify
  post "/login/verify", to: "sessions#confirm_email"

  # Routes for authentication via OmniAuth
  get "/auth/:provider/callback", to: "sessions#create"
  get "/auth/failure", to: "sessions#failure"
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
  get "/qr-code/login-phone-demo" => "qr_codes#login_phone_demo", as: :login_phone_demo

  # we no longer expose a global /events index; everything is scoped to an
  # organisation. any remaining references to non-nested event routes should
  # be removed or updated accordingly.

  # public apply page using only the alphanumeric token (no org context)
  get "/:apply_token/apply", to: "events#apply_by_token", as: :public_apply_event
  post "/:apply_token/apply", to: "events#apply_create"

  # Admin dashboard (single page - no :id required)
  get "admin" => "admin#index", as: :admin

  # Serve guide assets from private storage through the Guides controller.
  get "learn/assets/*path", to: "guides#asset", as: :guide_asset, format: false
  get "learn/docs/*path", to: "guides#doc", as: :guide_doc, format: false

  resources :guides, path: "learn" do
    collection do
      get :getting_started
      get :organisations
      get :events
      get :attendees
      get :faqs
    end
  end

  # organisations with nested events
  resources :organisations, path: "org" do
    collection do
      get :setting
      get :admin
    end

    member do
      get "/public", to: "organisations#public", as: :public
      get "/join", to: "organisations#join", as: :join
      post "/favorite", to: "organisations#favorite", as: :favorite
      delete "/favorite", to: "organisations#favorite", as: :unfavorite
    end

    # introduce a member dashboard route that delegates to a dedicated
    # controller so that views may live under app/views/organisations/dashboard
    member do
      get :dashboard, to: "organisations/dashboard#index"
      # route for organisation dashboard events list
      get "dashboard/attendees", to: "organisations/dashboard/attendees#index", as: :dashboard_attendees
      get "dashboard/events", to: "organisations/dashboard/events#index", as: :dashboard_events
      get "dashboard/events/attendees", to: "organisations/dashboard/events#attendees", as: :dashboard_events_attendees
      get "dashboard/sub-teams", to: "organisations/dashboard/sub_teams#index", as: :dashboard_sub_teams
      post "dashboard/sub-teams", to: "organisations/dashboard/sub_teams#create", as: :dashboard_sub_teams_create
    end

    member do
      get :settings, to: "organisations/settings#index"
      get "settings/customisations", to: "organisations/settings#customisations", as: :settings_customisations
      get "settings/events-defaults", to: "organisations/settings#events_defaults", as: :settings_events_defaults
      get "settings/members", to: "organisations/settings#members", as: :settings_members
      get "settings/roles", to: "organisations/settings#roles", as: :settings_roles
      get "settings/branding", to: "organisations/settings#custom_branding", as: :settings_custom_branding

      # Future settings ideas:
      # get "settings/branding", to: "organisations/settings#branding", as: :settings_branding
      # get "settings/integrations", to: "organisations/settings#integrations", as: :settings_integrations
      # get "settings/audit-log", to: "organisations/settings#audit_log", as: :settings_audit_log
      #
      patch "settings/customisations", to: "organisations/settings#customisations_save"
      patch "settings/events-defaults", to: "organisations/settings#default_events_save"
      patch "settings/members", to: "organisations/settings#update_member", as: :settings_members_update
      patch "settings/branding", to: "organisations/settings#custom_branding_save", as: :settings_custom_branding_save
    end

    member do
      get "roles/new", to: "roles#new", as: :new_role
      get "roles/from-existing", to: "roles#select_template", as: :new_role_from_existing
      get "roles/from-template", to: "roles#select_template", as: :new_role_from_template
      post "roles", to: "roles#create", as: :create_role
      get "roles/:role_id/edit", to: "roles#edit", as: :edit_role
      patch "roles/:role_id", to: "roles#update", as: :update_role
      delete "roles/:role_id", to: "roles#destroy", as: :destroy_role
    end

    resources :events do
      member do
        get "attendees", to: "events#attendees", as: :attendees
        post "send_qr_codes", to: "organisations/dashboard/events#send_qr_codes"

        # show a specific attendee linked from the events list
        # view a specific attendee for this event
        get "attendee/:attendee_id", to: "events/attendees#attendee", as: :attendee
        # editing existing attendee
        get "attendee/:attendee_id/edit", to: "events/attendees#edit_attendee", as: :edit_attendee
        patch "attendee/:attendee_id", to: "events/attendees#update_attendee"

        # view specific attendee waiver
        get "attendee/:attendee_id/waiver", to: "events/attendees#attendee_waiver", as: :attendee_waiver
        delete "attendee/:attendee_id/waiver", to: "events/attendees#destroy_attendee_waiver", as: :destroy_attendee_waiver

        # sign‑up form and submission
        get "apply", to: "events#apply", as: :apply
        post "apply", to: "events#apply_create", as: :apply_create
        get "actions/sign-in",  to: "events#sign_in", as: :attendee_sign_in
        get "actions/sign-out", to: "events#sign_out", as: :attendee_sign_out
        get "actions/get-info", to: "events#get_info", as: :attendee_get_info
        post "actions/scan", to: "events#scan", as: :scan
      end
    end
  end
end
