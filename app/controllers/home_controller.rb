class HomeController < ApplicationController
  before_action :require_authentication, only: [ :dashboard ]

  def index
    if current_user
      redirect_to dashboard_path
    else
      redirect_to login_path
    end
  end

  def login
    if current_user
      redirect_to dashboard_path
    end
    # This will render the login page
  end

  def dashboard
    @user = current_user
    @wallets = @user.wallets.includes(:transactions)
    @total_balance = @wallets.sum { |wallet| wallet.balance || 0 }
  end

  private

  def require_authentication
    unless current_user
      redirect_to login_path, alert: "Please log in to access this page."
    end
  end
end
