require 'rails_helper'

describe '/app/login', type: :request do
  context 'without DEFAULT_LOCALE' do
    it 'renders the dashboard' do
      get '/app/login'
      expect(response).to have_http_status(:success)
    end
  end

  context 'with DEFAULT_LOCALE' do
    it 'renders the dashboard' do
      with_modified_env DEFAULT_LOCALE: 'pt_BR' do
        get '/app/login'
        expect(response).to have_http_status(:success)
        expect(response.body).to include "selectedLocale: 'pt_BR'"
      end
    end
  end

  context 'with OIDC login configured' do
    it 'offers the OIDC login method and its label' do
      with_modified_env OIDC_ISSUER: 'https://login.example.com/application/o/chatwoot/', OIDC_CLIENT_ID: 'chatwoot',
                        OIDC_CLIENT_SECRET: 'secret', OIDC_LOGIN_LABEL: 'Mit Schlaile-Login anmelden' do
        get '/app/login'
        expect(response.body).to include('"oidc"')
        expect(response.body).to include("oidcLoginLabel: 'Mit Schlaile-Login anmelden'")
      end
    end

    it 'does not offer OIDC without a client secret' do
      with_modified_env OIDC_ISSUER: 'https://login.example.com/application/o/chatwoot/', OIDC_CLIENT_ID: 'chatwoot' do
        get '/app/login'
        expect(response.body).not_to include('"oidc"')
      end
    end
  end

  context 'with non-HTML format' do
    it 'returns not acceptable for JSON with error message' do
      get '/app/login', headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:not_acceptable)
      expect(response.parsed_body).to eq({ 'error' => 'Please use API routes instead of dashboard routes for JSON requests' })
    end
  end

  # Routes are loaded once on app start
  # hence Rails.application.reload_routes! is used in this spec
  # ref : https://stackoverflow.com/a/63584877/939299
  context 'with CW_API_ONLY_SERVER true' do
    it 'returns 404' do
      with_modified_env CW_API_ONLY_SERVER: 'true' do
        Rails.application.reload_routes!
        get '/app/login'
        expect(response).to have_http_status(:not_found)
      end
      Rails.application.reload_routes!
    end
  end
end
