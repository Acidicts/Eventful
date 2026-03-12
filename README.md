# Eventful

This Rails application uses Hack Club's OAuth provider for user authentication.

## OAuth integration

The flow is handled by OmniAuth with a custom [hackclub strategy](lib/omniauth/strategies/hackclub.rb).
Key configuration points:

1. **Environment variables** – set `HACKCLUB_CLIENT_ID` and `HACKCLUB_CLIENT_SECRET` (see `.env` for development; you can copy `.env.example`).
2. **Callback URL** – the provider must be configured to redirect to
   `#{OmniAuth.config.full_host}/auth/hackclub/callback`. In development we force
   `OmniAuth.config.full_host` to `http://dev.bing-bong.uk:3000`; adjust or
   change to `localhost:3000` depending on how you access the app.
3. **Scopes** – we request `openid profile email slack_id verification_status
   offline_access` so that:
   * we can read basic profile information (`/api/v1/me`), and
   * receive refresh tokens for long‑lived sessions.
   The offline scope is what gives us a `refresh_token` from the API.
4. **SessionsController#create** stores the omniauth hash in the database.

### Token storage & refreshing

`User` records now include `access_token`, `refresh_token` and `expires_at`
(columns added in `db/migrate/20260303180000_add_oauth_tokens_to_users.rb`).
`User.from_omniauth` saves credentials from the callback and provides
`refresh_access_token!` to rotate tokens when they expire.  Example:

```ruby
if current_user.access_token_expired?
  current_user.refresh_access_token!
end
response = current_user.hackclub_get("/api/v1/me")
``` 

### Development and testing

- Tests exercise the full sign‑in flow (including credential storage) via
  OmniAuth's test mode.  Run `bin/rails test` after migrating the test DB.
- To try the real flow, start the server and click **Sign in with Hack Club**.

Happy hacking!

## Location autocomplete

Events now support address autocompletion with two different providers:

* **Google Maps Places API ("Autocomplete (New)")** – uses the new HTTP POST endpoint (`/v1/places:autocomplete`) so no Maps JavaScript library is required. A valid API key is still necessary; this request is billed under the Places SKU.
* **OpenStreetMap / Nominatim** – a free, unauthenticated service that returns basic place names and works automatically when no Google API key is configured.

### behaviour
The `location` field on the event form is wired up to a Stimulus controller (`LocationAutocompleteController`). The controller reads the key from a `<meta name="google-maps-api-key" …>` tag injected by the layout.

* When a key is present it sends debounced POST requests to `https://places.googleapis.com/v1/places:autocomplete` with a JSON body containing `{"input":"…"}`. The response is parsed and the first five suggestions are shown via a `<datalist>`.
* If the key is blank, Nominatim is used instead; this branch has unchanged behaviour and also fills the datalist.

### enabling Google
1. Obtain an API key from the Google Cloud Console and enable the **Places API**.
2. Set `GOOGLE_MAPS_API_KEY` in your environment (e.g. in `.env` for development).
3. Restart the server. The layout will expose the key in a meta tag and the controller will begin calling the HTTP endpoint.

You can bias results using additional data‑attributes if desired (e.g. `data-location-bias`), or modify the controller to include parameters such as `locationRestriction`, `regionCode`, etc. See Google’s documentation for the full set of request options.

If you never configure a key, the Nominatim fallback ensures the form remains usable at no cost.

Happy hacking!

## Image processing dependency

Active Storage generates image variants for display (e.g. event icons).  By
default the `image_processing` gem prefers the `ruby-vips` backend which
requires the `libvips` library to be installed on the system.  In development
and the CI container we don’t rely on that library, so the application is
configured to use `MiniMagick` instead.

You still need to have [ImageMagick](https://imagemagick.org) installed:

```sh
# Ubuntu / WSL
sudo apt-get install imagemagick
# macOS (Homebrew)
brew install imagemagick
```

Without ImageMagick the app will raise a 500 error when generating a variant:
```
MiniMagick::Error (executable not found: "convert")
```
The initializer included with the project will log a warning and automatically
switch to `:vips` if the `libvips` library is already present (and the
`ruby-vips` gem loaded successfully).  In that case you can either install
ImageMagick or simply leave the fallback in place.

If you *do* install `libvips` you can remove the initializer or change the
processor back to `:vips` altogether.

Happy hacking!

