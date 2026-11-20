require 'rails_helper'

# OIDC login (e.g. Authentik). The strategy is only mounted when OIDC_* is set,
# so these examples hand the auth hash to the callback route directly, the way
# the OmniAuth middleware would.
RSpec.describe 'DeviseOverrides::OmniauthCallbacksController OIDC login', type: :request do
  def oidc_auth(email)
    OmniAuth::AuthHash.new(provider: 'openid_connect', uid: 'authentik-sub-1', info: { name: 'Test', email: email })
  end

  def oidc_callback(email)
    get '/omniauth/openid_connect/callback', env: { 'omniauth.auth' => oidc_auth(email) }
  end

  around do |example|
    with_modified_env(FRONTEND_URL: 'http://www.example.com') { example.run }
  end

  it 'signs in an existing agent without a second redirect' do
    user = create(:user, email: 'agent@example.com')

    oidc_callback('Agent@Example.com')

    expect(response).to redirect_to(%r{\Ahttp://www.example.com/app/login\?email=agent%2540example.com&sso_auth_token=.+\z})
    token = Rack::Utils.parse_query(URI(response.location).query)['sso_auth_token']
    expect(user.reload.valid_sso_auth_token?(token)).to be(true)
  end

  it 'never creates users or accounts' do
    with_modified_env ENABLE_ACCOUNT_SIGNUP: 'true' do
      expect { oidc_callback('stranger@example.com') }.not_to change(User, :count)
    end

    expect(response).to redirect_to('http://www.example.com/app/login?error=no-account-found')
  end

  it 'rejects an auth hash without email' do
    oidc_callback(nil)

    expect(response).to redirect_to('http://www.example.com/app/login?error=no-account-found')
  end

  it 'sends provider failures back to the login page' do
    get '/omniauth/failure', params: { strategy: 'openid_connect', message: 'invalid_credentials' }

    expect(response).to redirect_to('http://www.example.com/app/login?error=sso-authentication-failed')
  end
end
