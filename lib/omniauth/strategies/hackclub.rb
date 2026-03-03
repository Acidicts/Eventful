require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class Hackclub < OmniAuth::Strategies::OAuth2
      option :name, "hackclub"

      option :client_options, {
        site: "https://auth.hackclub.com",
        authorize_url: "/oauth/authorize",
        token_url: "/oauth/token"
      }

      # The standard OIDC userinfo endpoint; guaranteed to work with the
      # scopes_supported list from the discovery doc (openid / profile).
      uid { userinfo["sub"] }

      info do
        {
          name: userinfo["name"] ||
                "#{userinfo['given_name']} #{userinfo['family_name']}".strip,
          email:               userinfo["email"],
          slack_id:            userinfo["slack_id"],
          verification_status: userinfo["verification_status"],
          admin:               userinfo["admin"]
        }
      end

      extra do
        { "raw_info" => userinfo }
      end

      def userinfo
        @userinfo ||= access_token.get("/oauth/userinfo").parsed
      end

      # Keep the old name so existing callers (User#hackclub_get etc.) still work.
      alias raw_info userinfo
    end
  end
end
