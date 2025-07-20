require "test_helper"

class Api::V1::AuthControllerTest < ActionController::TestCase
  def setup
    @user = users(:one)
  end

    test "should get current user when authenticated" do
    # Set session directly for API test
    session[:user_id] = @user.id

    get :me
    assert_response :success

    json = JSON.parse(response.body)
    assert json["user"]["id"] == @user.id
    assert json["user"]["email"] == @user.email
    assert json["user"]["name"] == @user.name
  end

  test "should return unauthorized when not authenticated" do
    get :me
    assert_response :unauthorized

    json = JSON.parse(response.body)
    assert json["error"] == "Authentication required"
  end

    test "should include wallet count in user data" do
    # Set session directly for API test
    session[:user_id] = @user.id

    get :me
    assert_response :success

    json = JSON.parse(response.body)
    assert json["wallets_count"] == @user.wallets.count
  end

  test "should handle missing user id in session" do
    # Simulate missing user id
    session[:user_id] = nil

    get :me
    assert_response :unauthorized

    json = JSON.parse(response.body)
    assert json["error"] == "Authentication required"
  end
end
