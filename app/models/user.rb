class User < ApplicationRecord
  belongs_to :organisation, optional: true

  validates :provider, :uid, presence: true

  # Build or update a User record from OmniAuth auth hash
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_initialize.tap do |user|
      user.name                = auth.info.name
      user.email               = auth.info.email
      user.slack_id            = auth.info.slack_id
      user.verification_status = auth.info.verification_status
      user.admin               = false

      # store the OAuth tokens so we can make API requests on behalf of the
      # user and refresh them later if necessary.  OmniAuth/OAuth2 puts the
      # values in `credentials`.
      if auth.credentials
        user.access_token  = auth.credentials.token
        user.refresh_token = auth.credentials.refresh_token
        user.expires_at    = Time.at(auth.credentials.expires_at) if auth.credentials.expires_at
      end

      user.save!
    end
  end

  # Refresh the access token using the stored refresh token.  Hack Club's
  # OAuth implementation returns a new access/refresh pair each time, so we
  # rotate the stored values.  This mirrors the instructions in the API
  # documentation the application author shared.
  def refresh_access_token!
    return unless refresh_token.present?

    client = OAuth2::Client.new(
      ENV.fetch("HACKCLUB_CLIENT_ID"),
      ENV.fetch("HACKCLUB_CLIENT_SECRET"),
      site: "https://auth.hackclub.com",
      token_url: "/oauth/token"
    )

    token = OAuth2::AccessToken.new(client, access_token, refresh_token: refresh_token, expires_at: expires_at&.to_i)
    new_token = token.refresh!

    update!(
      access_token:  new_token.token,
      refresh_token: new_token.refresh_token,
      expires_at:    Time.at(new_token.expires_at)
    )
  end

  # Make a GET request to the Hack Club Auth API on behalf of the user.
  # Automatically refreshes the token if it has expired, then adds the
  # bearer token to the Authorization header.
  def hackclub_get(path)
    refresh_access_token! if expires_at.present? && expires_at.past?

    Faraday.get("https://auth.hackclub.com#{path}") do |req|
      req.headers["Authorization"] = "Bearer #{access_token}"
      req.headers["Accept"] = "application/json"
    end
  end
end
