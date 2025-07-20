ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Coverage configuration
require "simplecov"
SimpleCov.start "rails" do
  add_filter "/test/"
  add_filter "/config/"
  add_filter "/vendor/"

  add_group "Models", "app/models"
  add_group "Controllers", "app/controllers"
  add_group "Services", "app/services"
  add_group "Jobs", "app/jobs"
end

# Mocking and stubbing
require "mocha/minitest"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Ensure database is cleaned between tests
  setup do
    # Reset any global state that might persist between tests
    BlockchainState.set_processing_lock_state(false) if defined?(BlockchainState)
  end

  # Add more helper methods to be used by all tests here...
end

# Custom assertions
module CustomAssertions
  def assert_valid_ethereum_address(address)
    # Handle both string and Eth::Address objects
    address_str = address.is_a?(String) ? address : address.to_s
    assert address_str.match?(/^0x[a-fA-F0-9]{40}$/),
           "Expected valid Ethereum address, got: #{address_str}"
  end

  def assert_valid_transaction_hash(hash)
    # Handle both string and Eth::Hash objects
    hash_str = hash.is_a?(String) ? hash : hash.to_s
    assert hash_str.match?(/^0x[a-fA-F0-9]{64}$/),
           "Expected valid transaction hash, got: #{hash_str}"
  end
end

# Test helpers
module AuthHelper
  def sign_in(user)
    if respond_to?(:session)
      session[:user_id] = user.id
    else
      # For integration tests that don't have session
      @current_user = user
    end
  end

  def sign_out
    if respond_to?(:session)
      session[:user_id] = nil
    else
      @current_user = nil
    end
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end
end

module BlockchainHelper
  def mock_blockchain_responses
    EthereumService.stub :get_latest_block_number, 1000
    EthereumService.stub :get_balance, 1.5
    EthereumService.stub :send_transaction, "0xabc123"
  end
end

# Include helpers in test classes
class ActionDispatch::IntegrationTest
  include AuthHelper
  include BlockchainHelper
  include CustomAssertions
end

class ActiveSupport::TestCase
  include CustomAssertions
end
