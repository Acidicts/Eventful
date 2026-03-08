Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Routes for authentication via OmniAuth
  get "/auth/:provider/callback", to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  # a simple root for now
  root "home#index"

  # QR code generator/decoder
  resource :qr_code, only: [ :new, :create ] do
    collection do
      get :decode
    end
  end

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
        # show a specific attendee linked from the events list
        # view a specific attendee for this event
        get "attendee/:attendee_id", to: "events#attendee", as: :attendee
        # editing existing attendee
        get "attendee/:attendee_id/edit", to: "events#edit_attendee", as: :edit_attendee
        patch "attendee/:attendee_id", to: "events#update_attendee"

        # sign‑up form and submission
        get "apply", to: "events#apply"
        post "apply", to: "events#apply_create"
        get "actions/sign-in",  to: "events#sign_in"
        get "actions/sign-out", to: "events#sign_out"
        get "actions/get-info", to: "events#get_info"
      end
    end
  end
end
