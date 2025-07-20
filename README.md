# Dynamic Labs Custodial Wallet API

A Ruby on Rails-based POC for custodial wallets that allows users to create and manage Ethereum wallets with full blockchain interaction capabilities.

## Live Demo

Live demo hosted on heroku during limited time, you can access it [HERE](https://dynamic-challenge-4811e7207f39.herokuapp.com/dashboard)

## Features

- **Auth0 Authentication** - Secure user authentication
- **Wallet Management** - Create and manage multiple wallets
- **Transaction Sending** - Send ETH to any address
- **Message Signing** - Sign messages with private keys
- **Balance Tracking** - Real-time wallet balances
- **Transaction History** - Complete transaction tracking
- **Blockchain Sync** - Automated incoming transaction detection
- **EIP-1559 Support** - Modern gas fee strategy

## Architecture

- **Backend**: Ruby on Rails 7 API
- **Database**: PostgreSQL
- **Cache/Queue**: Redis + Sidekiq
- **Blockchain**: Ethereum Sepolia testnet
- **Authentication**: Auth0
- **Frontend**: Rails views with JavaScript

## Documentation

- [API Documentation](docs/API.md)
- [Architecture Overview](docs/ARCHITECTURE.md)
- [Blockchain Integration](docs/BLOCKCHAIN.md)
- [Setup Guide](docs/SETUP.md)
- [Main Considerations](docs/CONSIDERATIONS.md)

## License

This project is part of the Dynamic Labs take-home challenge.
