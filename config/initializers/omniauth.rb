# OmniAuth configuration
# Sets the full host URL for callbacks and proper redirect handling
OmniAuth.config.full_host = ENV.fetch('FRONTEND_URL', 'http://localhost:3000')

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV.fetch('GOOGLE_OAUTH_CLIENT_ID', nil), ENV.fetch('GOOGLE_OAUTH_CLIENT_SECRET', nil), {
    provider_ignores_state: true
  }

  # Single sign-on against an OpenID Connect provider such as Authentik.
  # OIDC_ISSUER is the provider's issuer URL, e.g.
  # https://login.example.com/application/o/chatwoot/ (endpoints come from discovery).
  # Users are matched by email; OIDC login never creates users or accounts.
  if ChatwootApp.oidc_login_enabled?
    provider :openid_connect, {
      name: :openid_connect,
      issuer: ENV.fetch('OIDC_ISSUER'),
      discovery: true,
      response_type: :code,
      scope: %i[openid email profile],
      pkce: true,
      client_options: {
        identifier: ENV.fetch('OIDC_CLIENT_ID'),
        secret: ENV.fetch('OIDC_CLIENT_SECRET'),
        redirect_uri: "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/omniauth/openid_connect/callback"
      }
    }
  end
end
