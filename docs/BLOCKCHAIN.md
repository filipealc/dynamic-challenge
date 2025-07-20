# Blockchain Integration

## ⛓️ Overview

The Dynamic Labs Custodial Wallet API integrates with the Ethereum blockchain to provide wallet management, transaction processing, and blockchain state monitoring.

## Architecture

### Blockchain Layer

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │    │   Ethereum      │    │   Blockchain    │
│   (Rails API)   │◄──►│   Service       │◄──►│   (Sepolia)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │   Background    │
                       │   Jobs          │
                       └─────────────────┘
```

## Core Components

### 1. EthereumService

The main service for blockchain interactions:

```ruby
class EthereumService
  # Wallet creation
  def self.create_wallet

  # Balance queries
  def self.get_balance(address)

  # Transaction sending
  def self.send_transaction(from, to, amount, private_key)

  # Message signing
  def self.sign_message(message, private_key)

  # Blockchain queries
  def self.get_latest_block_number
  def self.get_block_transactions(block_number)
end
```

### 2. Background Jobs

- **CheckIncomingTransactionsJob**: Scans blockchain for incoming transactions
- **TransactionMonitorJob**: Monitors outgoing transaction confirmations

### 3. Blockchain State Management

- **BlockchainState**: Tracks sync status and processing locks
- **Job Locking**: Prevents overlapping blockchain operations
