class Api::V1::BaseController < ApplicationController
  # API controllers use JSON format and token authentication
  before_action :authenticate_api_user

  protect_from_forgery with: :null_session

  private

  def authenticate_api_user
    # For API endpoints, we can use session-based auth since our frontend calls the API
    unless logged_in?
      render json: { error: "Authentication required" }, status: :unauthorized
    end
  end

  def render_error(message, status = :unprocessable_entity)
    render json: { error: message }, status: status
  end

  def render_success(data, message = nil)
    response = data
    response = response.merge(message: message) if message
    render json: response
  end
end
