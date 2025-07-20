class EthereumService
  class << self
    def sepolia_config
      Rails.application.credentials.dig(Rails.env.to_sym, :blockchain, :sepolia) || {
        rpc_url: ENV["SEPOLIA_RPC_URL"],
        chain_id: 11155111
      }
    end

    def create_wallet
      key = Eth::Key.new

      {
        private_key: key.private_hex,
        address: key.address
      }
    end

    def get_balance(address)
      response = rpc_call("eth_getBalance", [ address, "latest" ])
      wei_balance = response["result"].to_i(16)
      wei_balance / 1e18
    rescue => e
      Rails.logger.error "Failed to get balance for #{address}: #{e.message}"
      0.0
    end

    def sign_message(message, private_key)
      key = Eth::Key.new(priv: private_key)
      signature = key.personal_sign(message)

      # The eth gem returns a signature without 0x prefix
      # Ethereum signatures should be 65 bytes (130 hex characters)
      # Add 0x prefix if missing
      signature = "0x#{signature}" unless signature.start_with?("0x")

      # Ensure it's exactly 132 characters (0x + 130 hex chars)
      if signature.length != 132
        Rails.logger.warn "Unexpected signature length: #{signature.length} for signature: #{signature}"
      end

      signature
    rescue => e
      Rails.logger.error "Failed to sign message: #{e.message}"
      raise "Failed to sign message: #{e.message}"
    end

    def send_transaction(from_address, to_address, amount, private_key)
      key = Eth::Key.new(priv: private_key)

      # Get current gas price with buffer
      gas_price = get_gas_price_with_buffer

      # Get nonce
      nonce = get_nonce(from_address)

      # Build transaction
      tx_params = {
        to: to_address,
        value: (amount * 1e18).to_i,
        gas_limit: 21_000,
        gas_price: gas_price,
        nonce: nonce,
        chain_id: sepolia_config[:chain_id]
      }

      tx = Eth::Tx.new(tx_params)

      # Sign transaction
      tx.sign(key)

      # Get hex and ensure it starts with 0x
      tx_hex = tx.hex
      tx_hex = "0x#{tx_hex}" unless tx_hex.start_with?("0x")

      # Send to network
      response = rpc_call("eth_sendRawTransaction", [ tx_hex ])

      tx_hash = response["result"]

      tx_hash
    rescue => e
      Rails.logger.error "Failed to send transaction: #{e.message}" \
        "Transaction details: from=#{from_address}, to=#{to_address}, amount=#{amount}" \
        "Full error: #{e.backtrace.join("\n")}"
      raise "Failed to send transaction: #{e.message}"
    end

    def get_transaction_receipt(tx_hash)
      response = rpc_call("eth_getTransactionReceipt", [ tx_hash ])
      response["result"]
    rescue => e
      Rails.logger.error "Failed to get transaction receipt for #{tx_hash}: #{e.message}"
      nil
    end

    def get_gas_price_estimates
      response = rpc_call("eth_gasPrice", [])
      base_price = response["result"].to_i(16)

      {
        slow: base_price,
        standard: (base_price * 1.2).to_i,
        fast: (base_price * 1.5).to_i
      }
    rescue => e
      Rails.logger.error "Failed to get gas price: #{e.message}"
      # Return default values in case of error
      {
        slow: 1_000_000_000,
        standard: 2_000_000_000,
        fast: 5_000_000_000
      }
    end

    def get_latest_block_number
      response = rpc_call("eth_blockNumber", [])
      response["result"].to_i(16)
    rescue => e
      Rails.logger.error "Failed to get latest block number: #{e.message}"
      0
    end

    def get_block_with_transactions(block_number)
      response = rpc_call("eth_getBlockByNumber", [ "0x#{block_number.to_i.to_s(16)}", true ])
      response["result"]
    rescue => e
      Rails.logger.error "Failed to get block #{block_number} data: #{e.message}"
      nil
    end

    private

    def rpc_call(method, params)
      # Debug log to verify if we are not being crazy on the N of calls
      Rails.logger.info "RPC call: #{method} with params: #{params}"
      response = HTTParty.post(sepolia_config[:rpc_url], {
        body: {
          jsonrpc: "2.0",
          method: method,
          params: params,
          id: 1
        }.to_json,
        headers: { "Content-Type" => "application/json" },
        timeout: 30
      })

      parsed = JSON.parse(response.body)

      if parsed["error"]
        raise "RPC Error: #{parsed['error']['message']}"
      end

      parsed
    end

    def get_gas_price_with_buffer(buffer_percent = 20)
      estimates = get_gas_price_estimates
      estimates[:standard]
    end

    def get_nonce(address)
      response = rpc_call("eth_getTransactionCount", [ address, "latest" ])
      response["result"].to_i(16)
    end
  end
end
