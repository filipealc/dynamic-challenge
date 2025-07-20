namespace :blockchain do
  desc "Initialize blockchain state with current block number"
  task initialize: :environment do
    puts "Initializing blockchain state..."
    BlockchainState.initialize_with_current_block
    puts "Blockchain state initialized successfully!"
  end

  desc "Show current blockchain state"
  task status: :environment do
    last_block = BlockchainState.get_last_processed_block
    current_block = EthereumService.get_latest_block_number

    puts "Last processed block: #{last_block}"
    puts "Current blockchain block: #{current_block}"
    puts "Blocks to process: #{current_block - last_block}"
  end
end
