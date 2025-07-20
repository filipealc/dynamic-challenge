require "test_helper"

class EthereumServiceTest < ActiveSupport::TestCase
  test "should create wallet" do
    wallet_data = EthereumService.create_wallet
    assert wallet_data[:private_key].present?
    assert wallet_data[:address].present?
    assert_valid_ethereum_address(wallet_data[:address])
  end

  test "should get balance" do
    address = "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6"

    # Mock RPC response
    mock_response = { "result" => "0xde0b6b3a7640000" }  # 1 ETH in wei
    EthereumService.expects(:rpc_call).with("eth_getBalance", [ address, "latest" ]).returns(mock_response)

    balance = EthereumService.get_balance(address)
    assert_equal 1.0, balance
  end

  test "should handle balance errors gracefully" do
    address = "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6"

    # Mock RPC error
    EthereumService.expects(:rpc_call).with("eth_getBalance", [ address, "latest" ]).raises("RPC Error")

    balance = EthereumService.get_balance(address)
    assert_equal 0.0, balance
  end

  test "should sign messages" do
    message = "Hello, World!"
    private_key = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"

    signature = EthereumService.sign_message(message, private_key)
    assert signature.start_with?("0x")
    assert signature.length == 132  # 0x + 130 hex chars
  end

  test "should handle signing errors" do
    message = "Hello, World!"
    private_key = "invalid_key"

    assert_raises(RuntimeError) do
      EthereumService.sign_message(message, private_key)
    end
  end

  test "should send transactions" do
    from_address = "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6"
    to_address = "0x1234567890abcdef1234567890abcdef12345678"
    amount = 0.1
    private_key = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"

    # Mock the private methods directly
    EthereumService.expects(:get_gas_price_with_buffer).returns(1_000_000_000)
    EthereumService.expects(:get_nonce).with(from_address).returns(0)
    EthereumService.stubs(:rpc_call).returns({ "result" => "0xabc123" })

    tx_hash = EthereumService.send_transaction(from_address, to_address, amount, private_key)
    assert_equal "0xabc123", tx_hash
  end

  test "should handle transaction errors" do
    from_address = "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6"
    to_address = "0x1234567890abcdef1234567890abcdef12345678"
    amount = 0.1
    private_key = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"

    # Mock the get_gas_price_with_buffer method to raise an error
    EthereumService.expects(:get_gas_price_with_buffer).raises("Transaction failed")

    assert_raises(RuntimeError) do
      EthereumService.send_transaction(from_address, to_address, amount, private_key)
    end
  end

  test "should get transaction receipt" do
    tx_hash = "0xabc123"

    # Mock RPC response
    mock_response = { "result" => { "status" => "0x1", "blockNumber" => "0x123456" } }
    EthereumService.expects(:rpc_call).with("eth_getTransactionReceipt", [ tx_hash ]).returns(mock_response)

    receipt = EthereumService.get_transaction_receipt(tx_hash)
    assert_equal "0x1", receipt["status"]
    assert_equal "0x123456", receipt["blockNumber"]
  end

  test "should handle transaction receipt errors" do
    tx_hash = "0xabc123"

    # Mock RPC error
    EthereumService.expects(:rpc_call).with("eth_getTransactionReceipt", [ tx_hash ]).raises("RPC Error")

    receipt = EthereumService.get_transaction_receipt(tx_hash)
    assert_nil receipt
  end

  test "should get gas price estimates" do
    # Mock RPC response
    mock_response = { "result" => "0x3b9aca00" }  # 1 gwei
    EthereumService.expects(:rpc_call).with("eth_gasPrice", []).returns(mock_response)

    estimates = EthereumService.get_gas_price_estimates
    assert estimates[:slow] > 0
    assert estimates[:standard] > 0
    assert estimates[:fast] > 0
  end

  test "should handle gas price errors" do
    # Mock RPC error
    EthereumService.expects(:rpc_call).with("eth_gasPrice", []).raises("RPC Error")

    estimates = EthereumService.get_gas_price_estimates
    assert_equal 1_000_000_000, estimates[:slow]
    assert_equal 2_000_000_000, estimates[:standard]
    assert_equal 5_000_000_000, estimates[:fast]
  end

  test "should get latest block number" do
    # Mock RPC response
    mock_response = { "result" => "0x123456" }
    EthereumService.expects(:rpc_call).with("eth_blockNumber", []).returns(mock_response)

    block_number = EthereumService.get_latest_block_number
    assert_equal 0x123456, block_number
  end

  test "should handle block number errors" do
    # Mock RPC error
    EthereumService.expects(:rpc_call).with("eth_blockNumber", []).raises("RPC Error")

    block_number = EthereumService.get_latest_block_number
    assert_equal 0, block_number
  end

  test "should get block transactions" do
    block_number = 123456

    # Mock RPC response
    mock_response = {
      "result" => {
        "transactions" => [
          {
            "hash" => "0xabc123",
            "to" => "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6",
            "from" => "0x1234567890abcdef1234567890abcdef12345678",
            "value" => "0xde0b6b3a7640000"
          }
        ]
      }
    }
    EthereumService.expects(:rpc_call).with("eth_getBlockByNumber", [ "0x1e240", true ]).returns(mock_response)

    transactions = EthereumService.get_block_with_transactions(block_number)["transactions"]
    assert_equal 1, transactions.length
    assert_equal "0xabc123", transactions.first["hash"]
  end

  test "should handle empty block transactions" do
    block_number = 123456

    # Mock RPC response with no transactions
    mock_response = { "result" => { "transactions" => [] } }
    EthereumService.expects(:rpc_call).with("eth_getBlockByNumber", [ "0x1e240", true ]).returns(mock_response)

    transactions = EthereumService.get_block_with_transactions(block_number)["transactions"]
    assert_equal [], transactions
  end

  test "should handle block transactions errors" do
    block_number = 123456

    # Mock RPC error
    EthereumService.expects(:rpc_call).with("eth_getBlockByNumber", [ "0x1e240", true ]).raises("RPC Error")

    result = EthereumService.get_block_with_transactions(block_number)
    assert_equal nil, result
  end

  test "should get block with transactions" do
    block_number = 123456

    # Mock RPC response
    mock_response = {
      "result" => {
        "timestamp" => "0x5f5e100",
        "transactions" => [
          {
            "hash" => "0xabc123",
            "to" => "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6",
            "from" => "0x1234567890abcdef1234567890abcdef12345678",
            "value" => "0xde0b6b3a7640000"
          }
        ]
      }
    }
    EthereumService.expects(:rpc_call).with("eth_getBlockByNumber", [ "0x1e240", true ]).returns(mock_response)

    block_data = EthereumService.get_block_with_transactions(block_number)
    assert_equal "0x5f5e100", block_data["timestamp"]
    assert_equal 1, block_data["transactions"].length
  end

  test "should handle block data errors" do
    block_number = 123456

    # Mock RPC error
    EthereumService.expects(:rpc_call).with("eth_getBlockByNumber", [ "0x1e240", true ]).raises("RPC Error")

    block_data = EthereumService.get_block_with_transactions(block_number)
    assert_nil block_data
  end

  test "should get gas price with buffer" do
    # Mock gas price estimates
    estimates = { slow: 1_000_000_000, standard: 2_000_000_000, fast: 5_000_000_000 }
    EthereumService.expects(:get_gas_price_estimates).returns(estimates)

    gas_price = EthereumService.send(:get_gas_price_with_buffer)
    assert_equal 2_000_000_000, gas_price
  end

  test "should get nonce" do
    address = "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6"

    # Mock RPC response
    mock_response = { "result" => "0x5" }
    EthereumService.expects(:rpc_call).with("eth_getTransactionCount", [ address, "latest" ]).returns(mock_response)

    nonce = EthereumService.send(:get_nonce, address)
    assert_equal 5, nonce
  end

  test "should make RPC calls correctly" do
    method = "eth_blockNumber"
    params = []

    # Mock HTTParty response
    mock_response = mock("response")
    mock_response.expects(:body).returns('{"jsonrpc":"2.0","result":"0x123456","id":1}')

    HTTParty.expects(:post).returns(mock_response)

    result = EthereumService.send(:rpc_call, method, params)
    assert_equal "0x123456", result["result"]
  end

  test "should handle RPC errors" do
    method = "eth_blockNumber"
    params = []

    # Mock HTTParty response with error
    mock_response = mock("response")
    mock_response.expects(:body).returns('{"jsonrpc":"2.0","error":{"code":-32601,"message":"Method not found"},"id":1}')

    HTTParty.expects(:post).returns(mock_response)

    assert_raises(RuntimeError) do
      EthereumService.send(:rpc_call, method, params)
    end
  end

  test "should handle RPC timeout" do
    method = "eth_blockNumber"
    params = []

    # Mock HTTParty timeout
    HTTParty.expects(:post).raises(Net::ReadTimeout)

    assert_raises(RuntimeError) do
      EthereumService.send(:rpc_call, method, params)
    end
  end
end
