require 'rails_helper'

# Logging out of a Chatwoot session that came from OIDC also ends the
# provider session: sign_out hands the frontend the provider's end-session URL.
RSpec.describe 'OIDC logout', type: :request do
  let(:user) { create(:user) }
  let(:end_session) { 'https://login.example.com/application/o/chatwoot/end-session/' }
  let(:oidc_env) do
    { OIDC_ISSUER: 'https://login.example.com/application/o/chatwoot/', OIDC_CLIENT_ID: 'chatwoot',
      OIDC_CLIENT_SECRET: 'secret', FRONTEND_URL: 'https://chat.example.com' }
  end

  before do
    allow(OpenIDConnect::Discovery::Provider::Config).to receive(:discover!)
      .and_return(double(end_session_endpoint: end_session)) # rubocop:disable RSpec/VerifiedDoubles
  end

  around do |example|
    with_modified_env(**oidc_env) { example.run }
  end

  def sign_in_with_sso_token
    post '/auth/sign_in', params: { email: user.email, sso_auth_token: user.generate_sso_auth_token }, as: :json
    expect(response).to have_http_status(:ok)
    response.headers.slice('access-token', 'client', 'uid', 'token-type', 'expiry')
  end

  def sign_out(auth_headers)
    delete '/auth/sign_out', headers: auth_headers, as: :json
    expect(response).to have_http_status(:ok)
    response.parsed_body
  end

  it 'returns the end-session URL with the ID token for an OIDC session, once' do
    Oidc::LogoutService.remember_pending(user, 'the-id-token')
    headers = sign_in_with_sso_token

    body = sign_out(headers)

    url = URI(body['oidc_logout_url'])
    expect("#{url.scheme}://#{url.host}#{url.path}").to eq(end_session)
    expect(Rack::Utils.parse_query(url.query)).to eq(
      'id_token_hint' => 'the-id-token', 'post_logout_redirect_uri' => 'https://chat.example.com/app/login'
    )
    expect(Redis::Alfred.get("OIDC_ID_TOKEN::#{user.id}::#{headers['client']}")).to be_nil
  end

  it 'returns no end-session URL for a session without OIDC' do
    headers = sign_in_with_sso_token

    expect(sign_out(headers)).to eq('success' => true)
  end

  it 'keeps the ID token per session' do
    Oidc::LogoutService.remember_pending(user, 'first-id-token')
    first = sign_in_with_sso_token
    second = sign_in_with_sso_token

    expect(sign_out(second)).not_to have_key('oidc_logout_url')
    expect(sign_out(first)['oidc_logout_url']).to include('id_token_hint=first-id-token')
  end
end
