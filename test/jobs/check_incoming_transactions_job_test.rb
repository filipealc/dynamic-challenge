require "test_helper"
require "mocha/minitest"

class CheckIncomingTransactionsJobTest < ActiveJob::TestCase
  def setup
    @wallet = wallets(:one)
    BlockchainState.set_processing_lock_state(false)
  end

  test "should process incoming transactions" do
    # Mock blockchain responses
    EthereumService.expects(:get_latest_block_number).returns(1000)
    BlockchainState.expects(:get_last_processed_block).returns(999)
    EthereumService.expects(:get_block_with_transactions).with(1000).returns({
      "timestamp" => "0x5f5e100",
      "transactions" => [
        {
          "hash" => "0xabc123",
          "to" => @wallet.address,
          "from" => "0x1234567890abcdef1234567890abcdef12345678",
          "value" => "0xde0b6b3a7640000"  # 1 ETH
        }
      ]
    })

    assert_difference("Transaction.count") do
      CheckIncomingTransactionsJob.perform_now
    end

    transaction = Transaction.last
    assert_equal "receive", transaction.transaction_type
    assert_equal @wallet.id, transaction.wallet_id
    assert_equal "0xabc123", transaction.transaction_hash
    assert_equal 1.0, transaction.amount
    assert_equal "0x1234567890abcdef1234567890abcdef12345678", transaction.from_address
    assert_equal "confirmed", transaction.status
    assert_equal 1000, transaction.block_number
  end

  test "should not process duplicate transactions" do
    # Create existing transaction
    @wallet.transactions.create!(
      transaction_hash: "0xabc123",
      transaction_type: "receive",
      amount: 1.0,
      from_address: "0x1234567890abcdef1234567890abcdef12345678",
      status: "confirmed"
    )

    # Mock blockchain response with same transaction
    EthereumService.expects(:get_latest_block_number).returns(1000)
    BlockchainState.expects(:get_last_processed_block).returns(999)
    EthereumService.expects(:get_block_with_transactions).with(1000).returns({
      "timestamp" => "0x5f5e100",
      "transactions" => [
        {
          "hash" => "0xabc123",
          "to" => @wallet.address,
          "from" => "0x1234567890abcdef1234567890abcdef12345678",
          "value" => "0xde0b6b3a7640000"
        }
      ]
    })

    assert_no_difference("Transaction.count") do
      CheckIncomingTransactionsJob.perform_now
    end
  end
end
