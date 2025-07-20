# API Documentation

## Authentication

All API endpoints require authentication via Auth0. Users must be logged in to access the API.

### Authentication Flow

1. User logs in via Auth0
2. Session is established
3. API requests include session cookies
4. User context is available via `current_user`

## API Endpoints

### Base URL

```
http://localhost:3000/api/v1
```

### Response Format

All API responses follow this format:

```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": {
    // Response data
  }
}
```

## Wallet Management

### List Wallets

**GET** `/wallets`

Returns all wallets for the authenticated user.

**Response:**

```json
{
  "success": true,
  "data": {
    "wallets": [
      {
        "id": 1,
        "name": "My Wallet",
        "address": "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6",
        "balance": 1.5,
        "transaction_count": 5,
        "created_at": "2024-01-15T10:30:00Z"
      }
    ]
  }
}
```

### Create Wallet

**POST** `/wallets`

Creates a new wallet for the authenticated user.

**Request Body:**

```json
{
  "wallet": {
    "name": "New Wallet"
  }
}
```

**Response:**

```json
{
  "success": true,
  "message": "Wallet created successfully!",
  "data": {
    "wallet": {
      "id": 2,
      "name": "New Wallet",
      "address": "0x1234567890abcdef1234567890abcdef12345678",
      "created_at": "2024-01-15T11:00:00Z"
    }
  }
}
```

### Get Wallet Details

**GET** `/wallets/:id`

Returns detailed information about a specific wallet including recent transactions.

**Response:**

```json
{
  "success": true,
  "data": {
    "wallet": {
      "id": 1,
      "name": "My Wallet",
      "address": "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6",
      "balance": 1.5,
      "transactions": [
        {
          "id": 1,
          "transaction_hash": "0xabc123...",
          "transaction_type": "send",
          "to_address": "0x1234567890abcdef1234567890abcdef12345678",
          "from_address": "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6",
          "amount": 0.1,
          "status": "confirmed",
          "block_number": 1234567,
          "gas_used": 21000,
          "created_at": "2024-01-15T10:30:00Z",
          "etherscan_url": "https://sepolia.etherscan.io/tx/0xabc123..."
        }
      ],
      "created_at": "2024-01-15T10:00:00Z"
    }
  }
}
```

### Get Wallet Balance

**GET** `/wallets/:id/balance`

Returns the current balance of a wallet.

**Response:**

```json
{
  "success": true,
  "data": {
    "balance": 1.5
  }
}
```

## Transaction Operations

### Send Transaction

**POST** `/wallets/:id/send_transaction`

Sends ETH from the specified wallet to another address.

**Request Body:**

```json
{
  "to": "0x1234567890abcdef1234567890abcdef12345678",
  "amount": 0.1
}
```

**Response:**

```json
{
  "success": true,
  "message": "Transaction sent successfully!",
  "data": {
    "transaction_hash": "0xabc123def456789...",
    "to_address": "0x1234567890abcdef1234567890abcdef12345678",
    "amount": 0.1,
    "from_address": "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6",
    "status": "pending"
  }
}
```

### Sign Message

**POST** `/wallets/:id/sign_message`

Signs a message with the wallet's private key.

**Request Body:**

```json
{
  "message": "Hello, World!"
}
```

**Response:**

```json
{
  "success": true,
  "message": "Message signed successfully!",
  "data": {
    "message": "Hello, World!",
    "signature": "0x1234567890abcdef...",
    "wallet_address": "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6"
  }
}
```

## Transaction Types

### Send Transaction

- **Type**: `send`
- **Status**: `pending` → `confirmed`/`failed`
- **Monitoring**: Background job tracks confirmation

### Receive Transaction

- **Type**: `receive`
- **Status**: `confirmed` (immediately)
- **Detection**: Automated blockchain scanning

## Error Responses

### Validation Error

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "amount": ["must be greater than 0"],
    "to": ["is required"]
  }
}
```

### Insufficient Balance

```json
{
  "success": false,
  "message": "Insufficient balance. Available: 0.5 ETH"
}
```

### Authentication Error

```json
{
  "success": false,
  "message": "Authentication required"
}
```

### Not Found Error

```json
{
  "success": false,
  "message": "Wallet not found"
}
```

## 🔧 Rate Limiting

Currently, no rate limiting is implemented. Consider implementing rate limiting for production use.

## Transaction Status

### Pending

Transaction has been sent to the network but not yet confirmed.

### Confirmed

Transaction has been included in a block and confirmed on the blockchain.

### Failed

Transaction failed to be included in a block or was reverted.

## Timestamps

All timestamps are in ISO 8601 format (UTC):

- `created_at`: When the transaction was created in our system
- `blockchain_timestamp`: When the transaction was included in a block (if available)

## 🔗 External Links

### Etherscan

Each transaction includes an `etherscan_url` field that links to the transaction on Etherscan:

- **Testnet**: `https://sepolia.etherscan.io/tx/{hash}`
- **Mainnet**: `https://etherscan.io/tx/{hash}`
