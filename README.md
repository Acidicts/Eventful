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

