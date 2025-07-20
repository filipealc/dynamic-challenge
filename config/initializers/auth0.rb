Rails.application.config.middleware.use OmniAuth::Builder do
  provider(
    :auth0,
    Rails.application.credentials.dig(Rails.env.to_sym, :auth0, :client_id),
    Rails.application.credentials.dig(Rails.env.to_sym, :auth0, :client_secret),
    Rails.application.credentials.dig(Rails.env.to_sym, :auth0, :domain),
    callback_path: "/auth/auth0/callback",
    authorize_params: {
      scope: "openid email profile"
    },
    info_fields: "email,name,picture"
  )
end

# Disable CSRF protection for OmniAuth (common and safe approach)
# OAuth flow provides its own security mechanisms
OmniAuth.config.request_validation_phase = nil

# Configure session store
Rails.application.config.session_store :cookie_store,
  key: "_dynamic_wallet_challenge_session",
  secure: Rails.env.production?,
  httponly: true,
  expire_after: 7.days,
  secret: Rails.application.credentials.dig(Rails.env.to_sym, :session_secret) || Rails.application.credentials.secret_key_base

# Enable sessions for API mode
Rails.application.config.api_only = false
