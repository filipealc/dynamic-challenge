require "test_helper"
require "mocha/minitest"

class Api::V1::WalletsControllerTest < ActionController::TestCase
  def setup
    @user = users(:one)
    @wallet = @user.wallets.first
    session[:user_id] = @user.id
  end

  test "should get index" do
    get :index
    assert_response :success

    json = JSON.parse(response.body)
    assert json["wallets"].is_a?(Array)
    assert_equal @user.wallets.count, json["wallets"].length
  end

  test "should create wallet" do
    assert_difference("Wallet.count") do
      post :create, params: {
        wallet: { name: "New Wallet" }
      }
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert json["wallet"]["name"] == "New Wallet"
    assert json["wallet"]["address"].present?
  end

  test "should not create wallet without name" do
    assert_no_difference("Wallet.count") do
      post :create, params: {
        wallet: { name: "" }
      }
    end

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["error"].present?
  end

  test "should get wallet details" do
    get :show, params: { id: @wallet.id }
    assert_response :success

    json = JSON.parse(response.body)
    assert json["wallet"]["id"] == @wallet.id
    assert json["wallet"]["name"] == @wallet.name
    assert json["wallet"]["address"] == @wallet.address
    assert json["wallet"]["transactions"].is_a?(Array)
  end

  test "should not access other user wallet" do
    other_wallet = users(:two).wallets.first
    get :show, params: { id: other_wallet.id }
    assert_response :not_found
  end

  test "should sign message" do
    post :sign_message, params: {
      id: @wallet.id,
      message: "Hello, World!"
    }

    assert_response :success
    json = JSON.parse(response.body)
    assert json["signature"].start_with?("0x")
    assert json["message"] == "Message signed successfully!"
    assert json["wallet_address"] == @wallet.address
  end

  test "should not sign empty message" do
    post :sign_message, params: {
      id: @wallet.id,
      message: ""
    }

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["error"] == "Message is required"
  end

  test "should handle signing errors" do
    # Mock signing error
    EthereumService.expects(:sign_message).raises("Signing failed")

    post :sign_message, params: {
      id: @wallet.id,
      message: "Hello, World!"
    }

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["error"] == "Failed to sign message"
  end

  test "should send transaction" do
    to_address = "0x1234567890abcdef1234567890abcdef12345678"
    amount = 0.001

    # Mock blockchain response
    EthereumService.expects(:send_transaction).returns("0xabc123")

    post :send_transaction, params: {
      id: @wallet.id,
      to: to_address,
      amount: amount
    }

    assert_response :success
    json = JSON.parse(response.body)
    assert json["transaction_hash"] == "0xabc123"
    assert json["to_address"] == to_address
    assert json["amount"] == amount
    assert json["from_address"] == @wallet.address
    assert json["status"] == "pending"
  end

  test "should not send transaction without recipient" do
    post :send_transaction, params: {
      id: @wallet.id,
      to: "",
      amount: 0.001
    }

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["error"] == "Recipient address is required"
  end

  test "should not send transaction with invalid address" do
    post :send_transaction, params: {
      id: @wallet.id,
      to: "invalid-address",
      amount: 0.001
    }

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["error"] == "Invalid Ethereum address format"
  end

  test "should not send transaction with invalid amount" do
    post :send_transaction, params: {
      id: @wallet.id,
      to: "0x1234567890abcdef1234567890abcdef12345678",
      amount: 0
    }

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["error"] == "Amount must be greater than 0"
  end

  test "should not send transaction with negative amount" do
    post :send_transaction, params: {
      id: @wallet.id,
      to: "0x1234567890abcdef1234567890abcdef12345678",
      amount: -1
    }

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["error"] == "Amount must be greater than 0"
  end

  test "should handle insufficient balance" do
    # Mock low balance
    EthereumService.expects(:get_balance).returns(0.0)

    post :send_transaction, params: {
      id: @wallet.id,
      to: "0x1234567890abcdef1234567890abcdef12345678",
      amount: 1.0
    }

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["error"].include?("Insufficient balance")
  end

  test "should handle transaction errors" do
    # Mock transaction error
    EthereumService.expects(:send_transaction).raises("Transaction failed")

    post :send_transaction, params: {
      id: @wallet.id,
      to: "0x1234567890abcdef1234567890abcdef12345678",
      amount: 0.001
    }

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["error"] == "Failed to send transaction. Please try again."
  end

  test "should handle specific transaction errors" do
    # Mock insufficient funds error
    EthereumService.expects(:send_transaction).raises("insufficient funds")

    post :send_transaction, params: {
      id: @wallet.id,
      to: "0x1234567890abcdef1234567890abcdef12345678",
      amount: 0.001
    }

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["error"] == "Insufficient funds for transaction and gas fees"
  end

  test "should require authentication" do
    session[:user_id] = nil

    get :index
    assert_response :unauthorized

    post :create, params: { wallet: { name: "Test" } }
    assert_response :unauthorized

    get :show, params: { id: @wallet.id }
    assert_response :unauthorized
  end

  test "should handle non-existent wallet" do
    get :show, params: { id: 99999 }
    assert_response :not_found
    json = JSON.parse(response.body)
    assert json["error"] == "Wallet not found"
  end

  test "should handle non-existent wallet for signing" do
    post :sign_message, params: {
      id: 99999,
      message: "test"
    }
    assert_response :not_found
  end

  test "should handle non-existent wallet for sending" do
    post :send_transaction, params: {
      id: 99999,
      to: "0x1234567890abcdef1234567890abcdef12345678",
      amount: 0.001
    }
    assert_response :not_found
  end
end
