class ApplicationController < ActionController::Base
  # Only for API endpoints - disable CSRF protection
  # protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }

  # For HTML requests, use authenticity token
  protect_from_forgery with: :exception, unless: -> { request.format.json? }

  before_action :set_current_user

  private

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  helper_method :current_user

  def logged_in?
    !!current_user
  end
  helper_method :logged_in?

  def set_current_user
    @current_user = current_user
  end

  def require_authentication
    unless logged_in?
      if request.format.json?
        render json: { error: "Authentication required" }, status: :unauthorized
      else
        redirect_to login_path, alert: "Please log in to access this page."
      end
    end
  end
end
