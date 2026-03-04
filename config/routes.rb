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

  # organisations with nested events
  resources :organisations, path: "org" do
    resources :events do
      member do
        get "attendees", to: "events#attendees"
        get "actions/sign-in",  to: "events#sign_in"
        get "actions/sign-out", to: "events#sign_out"
        get "actions/get-info", to: "events#get_info"
      end
    end
  end
end
