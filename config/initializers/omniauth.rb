# Load custom strategies from lib directory
require Rails.root.join("lib/omniauth/strategies/hackclub")

# OmniAuth normally infers the host for callback URLs from the incoming request.
# In development we often hit the app via a custom hostname (e.g. dev.bing-bong.uk)
# or without TLS, so force the value so the provider can redirect correctly.
if Rails.env.development?
  # You must use a hostname that matches the callback URL configured in the
  # Hack Club OAuth application.  We default to localhost but can be overridden
  # via ENV so you can use a DNS name such as "dev.bing-bong.uk" or a
  # different port.
  OmniAuth.config.full_host = ENV.fetch("OMNIAUTH_FULL_HOST", "http://localhost:3000")
end

# OmniAuth 2.0+ enables POST-only requests for the initial "auth" phase to
# mitigate CSRF attacks.  Our UI now issues a POST, so we no longer have to
# permit GET.  This removes the CSRF warning seen in the log.
# See https://github.com/omniauth/omniauth/wiki/Changes-in-2.0
# We still handle only POST in our app, but OmniAuth's built-in
# authenticity protection is incompatible with Rails' CSRF token
# (it stores a different session key), and the middleware runs before
# the normal Rails forgery check.  Rather than fighting the stack order,
# just bypass OmniAuth's check – Rails will already verify the token when
# rendering the login form, and the button_to helper includes it.
OmniAuth.config.allowed_request_methods = [ :post ]

# disable the default validation phase (which raises an AuthenticityError)
# and replace with a no-op.  This keeps the POST‑only behaviour without the
# error seen in development logs.
OmniAuth.config.request_validation_phase = ->(_env) { }

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :hackclub,
           ENV["HACKCLUB_CLIENT_ID"],
           ENV["HACKCLUB_CLIENT_SECRET"],
           callback_url: "#{OmniAuth.config.full_host}/auth/hackclub/callback",
           # ask for the scopes we use in the app; offline_access gives us a
           # refresh token so we can keep the user logged in for six months.
           # The list is mostly static but can be overridden in development if
           # the provider returns an "invalid scope" error.  See
           # .env.example for an example.
           scope: ENV.fetch("HACKCLUB_OAUTH_SCOPES",
                             "openid profile email slack_id verification_status offline_access"),
           # Disable OmniAuth-OAuth2's state/CSRF verification.  The `state`
           # token is written to the session during the request phase but the
           # session cookie is not forwarded through the provider's cross-domain
           # redirect, so the check always fails.  The initial form POST is
           # already CSRF-protected by Rails' own authenticity token.
           provider_ignores_state: true
end
