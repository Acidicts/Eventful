class User < ApplicationRecord
  # users can be members of an organisation, and they may also be the owner
  # of one or more organisations.  the inverse relation is declared on
  # Organisation so that controllers can do `current_user.organisations.build`
  # when creating new records.
  belongs_to :organisation, optional: true
  has_and_belongs_to_many :organisation_roles
  has_many :email_login_otps, dependent: :delete_all


  # use positional argument style to avoid Ruby 3 keyword demotion issues
  # global role; use `member` key instead of `user` to avoid generating a
  # `user?` predicate that collides with other enums.
  enum :role, { member: "user", admin: "admin", superadmin: "superadmin" }

  validates :provider, :uid, presence: true
  validates :role, presence: true, inclusion: { in: roles.keys }

  # helper predicate used in views/controllers
  # the `role` enum already defines an `admin?` method, so this is mostly
  # here for clarity and to emphasise the difference from ``org_admin?``.
  def admin?
    role == "admin" || role == "superadmin"
  end

  # Provides an HSLA color string for the user's role, used by views for badges.
  # Opacity is parsed from the passed value (e.g. "50%" or 0.5), clamped to 0..1.
  # Matches the logic in `app/views/application/_username.html.erb`.
  def user_color(opacity = 1)
    opacity = case opacity
    when nil then 1.0
    when String
        if opacity.end_with?("%")
          opacity.to_f / 100.0
        else
          opacity.to_f
        end
    else
        opacity.to_f
    end

    opacity = [ [ opacity, 0.0 ].max, 1.0 ].min

    hue = case role
    when "superadmin" then 220
    when "admin" then 0
    else 0
    end

    saturation = case role
    when "superadmin" then 100
    when "admin" then 100
    else 0
    end

    lightness = case role
    when "superadmin" then 56
    when "admin" then 56
    else 50
    end

    "hsla(#{hue}, #{saturation}%, #{lightness}%, #{opacity})"
  end

  # Build or update a User record from OmniAuth auth hash
  # NOTE: role is **not** automatically assigned here; it defaults to "user"
  # and must be set manually by an administrator or another process.
  def in_organisation?(organisation)
    organisation_roles.where(organisation: organisation).exists?
  end

  def user_organisations
    Organisation.joins(:organisation_roles)
      .where(organisation_roles: { id: organisation_role_ids })
      .distinct
  end

  def active?
    SessionsController.sessions[id].present?
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_initialize.tap do |user|
      user.name                = auth.info.name
      user.email               = auth.info.email
      user.slack_id            = auth.info.slack_id
      user.verification_status = auth.info.verification_status
      user.role ||= "member"

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

  def admin?
    self.role == "admin" || self.role == "superadmin"
  end

  def superadmin?
    self.role == "superadmin"
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
