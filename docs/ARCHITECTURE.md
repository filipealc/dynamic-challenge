# Architecture Overview

## System Architecture

The Dynamic Labs Custodial Wallet API is built as a modern web application with a focus on security, scalability, and blockchain integration.

### High-Level Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   Blockchain    │
│   (Rails Views) │◄──►│   (Rails API)   │◄──►│   (Ethereum)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │   Database      │
                       │   (PostgreSQL)  │
                       └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │   Background    │
                       │   Jobs (Sidekiq)│
                       └─────────────────┘
```

### Models Relationship

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                USER MODEL                                   │
│                                    │                                        │
│                                    │ has_many :wallets                      │
│                                    │                                        │
│                                    ▼                                        │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                            WALLET MODEL                              │   │
│  │                                  │                                   │   │
│  │                                  │ has_many :transactions            │   │
│  │                                  │                                   │   │
│  │                                  ▼                                   │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐ │   │
│  │  │                        TRANSACTION MODEL                        │ │   │
│  │  └─────────────────────────────────────────────────────────────────┘ │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Global State                                   │
│                                    │                                        │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                      BLOCKCHAIN_STATE MODEL                         │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                              RELATIONSHIPS                                  │
└─────────────────────────────────────────────────────────────────────────────┘

User (1) ──────► (N) Wallet
├── Purpose: Multi-wallet support per user
├── Cascade: User deletion removes all associated wallets
└── Security: User isolation ensures wallet privacy

Wallet (1) ──────► (N) Transaction
├── Purpose: Complete transaction history per wallet
├── Cascade: Wallet deletion removes all associated transactions
└── Types: Both outgoing (send) and incoming (receive) transactions

BlockchainState (1) ──────► (Global)
├── Purpose: Track blockchain synchronization state
├── Singleton: Only one record exists for the entire system
└── Locking: Prevents concurrent blockchain scanning jobs

## Core Components

### 1. Authentication Layer

- **Auth0 Integration**: OAuth2/OIDC authentication
- **Session Management**: Secure session handling
- **User Isolation**: Multi-tenant user separation

### 2. Wallet Management

- **Key Generation**: Secure private/public key generation
- **Address Management**: Ethereum address creation and validation
- **Balance Tracking**: Real-time blockchain balance queries

### 3. Transaction Processing

- **Outgoing Transactions**: Sign and broadcast transactions
- **Incoming Transactions**: Automated blockchain monitoring
- **Transaction History**: Complete audit trail

### 4. Background Processing

- **Sidekiq**: Asynchronous job processing
- **Blockchain Sync**: Automated transaction detection
- **Job Locking**: Prevent overlapping operations

## Data Flow

### Wallet Creation

1. User authenticates via Auth0
2. System generates new Ethereum keypair
3. Wallet record created in database
4. Private key encrypted and stored

### Transaction Sending

1. User initiates transaction
2. System validates balance and parameters
3. Transaction signed with private key
4. Raw transaction broadcast to network
5. Transaction record created (pending)
6. Background job monitors confirmation

### Transaction Receiving

1. Background job scans new blocks
2. Identifies transactions to managed wallets
3. Creates transaction records with blockchain timestamps
4. Updates wallet balances

## Security Architecture

### Authentication

- Auth0 OAuth2/OIDC flow
- Secure session management
- User isolation and authorization

### API Security

- CSRF protection
- Input validation

## Technology Stack

### Backend

- **Ruby on Rails 7**: Web framework
- **PostgreSQL**: Primary database
- **Redis**: Caching and job queue
- **Sidekiq**: Background job processing

### Blockchain

- **Ethereum Sepolia**: Test network
- **eth gem**: Ruby Ethereum library
- **JSON-RPC**: Blockchain communication
- **EIP-1559**: Gas fee strategy

### Infrastructure

- **Docker**: Containerization
- **docker-compose**: Local development
- **Auth0**: Authentication service

## Scalability Considerations

### Current Limitations

- Single database instance
- Synchronous blockchain calls
- Limited caching strategy
- Poor security on key generation and private_key storage
```
