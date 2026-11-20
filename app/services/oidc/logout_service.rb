# Remembers the OIDC ID token of each Chatwoot login that came from the OIDC
# provider, so logging out of Chatwoot can end the provider session too
# (RP-initiated logout via the provider's end_session_endpoint).
#
# The callback only knows the user; the Chatwoot session (DeviseTokenAuth
# client) is created a moment later when the frontend redeems the
# sso_auth_token. The token therefore waits under a short-lived pending key
# and is moved to the client's key on that sign-in.
class Oidc::LogoutService
  PENDING_TTL = 10.minutes
  END_SESSION_CACHE_KEY = 'oidc_end_session_endpoint'.freeze

  class << self
    def remember_pending(user, id_token)
      return if user.blank? || id_token.blank?

      Redis::Alfred.setex(pending_key(user), id_token, PENDING_TTL)
    end

    def attach_to_client(user, client)
      return if user.blank? || client.blank?

      id_token = Redis::Alfred.get(pending_key(user))
      return if id_token.blank?

      Redis::Alfred.delete(pending_key(user))
      Redis::Alfred.setex(client_key(user, client), id_token, DeviseTokenAuth.token_lifespan)
    end

    # Forgets the session's ID token and returns where the browser should go
    # to end the provider session, or nil for sessions that did not come from OIDC.
    def logout_url(user, client)
      return if user.blank? || client.blank?

      key = client_key(user, client)
      id_token = Redis::Alfred.get(key)
      return if id_token.blank?

      Redis::Alfred.delete(key)
      endpoint = end_session_endpoint
      return if endpoint.blank?

      query = { id_token_hint: id_token, post_logout_redirect_uri: "#{ENV.fetch('FRONTEND_URL', nil)}/app/login" }.to_query
      "#{endpoint}?#{query}"
    end

    private

    def end_session_endpoint
      return unless ChatwootApp.oidc_login_enabled?

      Rails.cache.fetch(END_SESSION_CACHE_KEY, expires_in: 1.hour, skip_nil: true) do
        OpenIDConnect::Discovery::Provider::Config.discover!(ENV.fetch('OIDC_ISSUER')).end_session_endpoint
      end
    rescue StandardError => e
      Rails.logger.warn("OIDC end_session_endpoint discovery failed: #{e.class}: #{e.message}")
      nil
    end

    def pending_key(user)
      "OIDC_ID_TOKEN::PENDING::#{user.id}"
    end

    def client_key(user, client)
      "OIDC_ID_TOKEN::#{user.id}::#{client}"
    end
  end
end
