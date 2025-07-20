class Auth0Controller < ApplicationController
  def callback
    # Get user info from Auth0
    auth_info = request.env["omniauth.auth"]

    # Find or create user
    user = User.find_or_create_by(auth0_id: auth_info["uid"]) do |u|
      u.email = auth_info.dig("info", "email")
      u.name = auth_info.dig("info", "name")
      u.picture = auth_info.dig("info", "picture")
    end

    if user.persisted?
      # Create wallet if user doesn't have one
      if user.wallets.empty?
        WalletCreationService.create_wallet_for_user(user)
      end

      # Create session
      session[:user_id] = user.id
      session[:auth_info] = {
        name: user.name,
        email: user.email,
        picture: user.picture
      }

      redirect_to dashboard_path, notice: "Successfully logged in!"
    else
      redirect_to login_path, alert: "There was an error logging you in."
    end
  end

  def failure
    redirect_to login_path, alert: "Authentication failed."
  end

  def logout
    reset_session

    redirect_to logout_url, allow_other_host: true
  end

  private

  def logout_url
    # Build Auth0 logout URL using URI
    logout_params = {
      returnTo: root_url,
      client_id: Rails.application.credentials.dig(Rails.env.to_sym, :auth0, :client_id)
    }

    URI::HTTPS.build(host: Rails.application.credentials.dig(Rails.env.to_sym, :auth0, :domain), path: "/v2/logout", query: logout_params.to_query).to_s
  end
end
