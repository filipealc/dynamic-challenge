class WalletCreationService
  def self.create_wallet_for_user(user, wallet_name = nil, force_create = false)
    # Don't create if user already has wallets (unless force_create is true)
    if user.wallets.exists? && !force_create
      return nil
    end

    # Generate wallet using Ethereum service
    wallet_data = EthereumService.create_wallet

    # Determine wallet name
    name = wallet_name || "Wallet ##{user.wallets.count + 1}"

    # Create wallet record
    wallet = user.wallets.create!(
      name: name,
      address: wallet_data[:address].to_s.downcase, # Ensure address is lowercase cuz while reading from the blockchain, the address can be inconsistent
      private_key: wallet_data[:private_key]
    )
    wallet

  rescue => e
    Rails.logger.error "WalletCreationService: Failed to create wallet for user #{user.id}: #{e.message} Full error: #{e.backtrace.join("\n")}"
    raise e
  end
end
