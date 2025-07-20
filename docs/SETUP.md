# Setup Guide

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Git
- Auth0 account (for authentication)

### 1. Clone the Repository

```bash
git clone <repository-url>
cd dynamic-challenge
```

### 2. Environment Configuration

```bash
# Copy environment template
cp .env.example .env

# Edit environment variables
nano .env
```

## Development Setup

### Environment-Aware Docker Configuration

The application uses a single `docker-compose.yml` file that automatically switches between development and test environments based on the `RAILS_ENV` environment variable.

#### Development Environment

```bash
# Start development environment (default)
docker-compose up -d

# Or explicitly set development environment
RAILS_ENV=development docker-compose up -d

# Create and setup development database
RAILS_ENV=development docker-compose run --rm web bundle exec rails db:create
RAILS_ENV=development docker-compose run --rm web bundle exec rails db:migrate

# Check service status
docker-compose ps
```

#### Test Environment

```bash
# Start test environment
RAILS_ENV=test docker-compose up -d

# Create and setup test database
RAILS_ENV=test docker-compose run --rm web bundle exec rails db:create
RAILS_ENV=test docker-compose run --rm web bundle exec rails db:migrate

# Run tests
RAILS_ENV=test docker-compose exec web bundle exec rails test
```

### 3. Database Setup

The application automatically uses different databases based on the environment:

- **Development**: `dynamic_wallet_challenge_development`
- **Test**: `dynamic_wallet_challenge_test`

```bash
# For development
RAILS_ENV=development docker-compose run --rm web bundle exec rails db:create
RAILS_ENV=development docker-compose run --rm web bundle exec rails db:migrate

# For testing
RAILS_ENV=test docker-compose run --rm web bundle exec rails db:create
RAILS_ENV=test docker-compose run --rm web bundle exec rails db:migrate
```

### 4. Access the Application

- **Main App**: http://localhost:3000
- **Sidekiq Dashboard**: http://localhost:3000/sidekiq
- **API Base**: http://localhost:3000/api/v1

## Testing

### Running Tests

The application uses a separate test database to ensure test isolation.

#### Run All Tests

```bash
# Start test environment
RAILS_ENV=test docker-compose up -d

# Run all tests
RAILS_ENV=test docker-compose exec web bundle exec rails test
```

## Environment Variables

### Required Variables

```bash
# Auth0 Configuration
AUTH0_DOMAIN=your-domain.auth0.com
AUTH0_CLIENT_ID=your-client-id
AUTH0_CLIENT_SECRET=your-client-secret

# Blockchain Configuration
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/your-api-key

# Database Configuration (automatically set by Docker Compose)
DATABASE_URL=postgresql://postgres:postgres@db:5432/dynamic_wallet_challenge_${RAILS_ENV:-development}

# Redis Configuration
REDIS_URL=redis://redis:6379/0

# Rails Configuration
RAILS_ENV=development
SECRET_KEY_BASE=your-secret-key-base
```

### Optional Variables

```bash
# Logging
RAILS_LOG_LEVEL=info

# Sidekiq Configuration
SIDEKIQ_CONCURRENCY=5

# Blockchain Configuration
CHAIN_ID=11155111  # Sepolia testnet
```

## Auth0 Setup

### 1. Create Auth0 Application

1. Go to [Auth0 Dashboard](https://manage.auth0.com/)
2. Create a new application
3. Choose "Regular Web Application"
4. Configure settings:
   - **Allowed Callback URLs**: `http://localhost:3000/auth/auth0/callback`
   - **Allowed Logout URLs**: `http://localhost:3000`
   - **Allowed Web Origins**: `http://localhost:3000`

### 2. Configure OmniAuth

The application uses OmniAuth for Auth0 integration. Configuration is in `config/initializers/omniauth.rb`.

### 3. Test Authentication

1. Start the application
2. Click "Login" or "Sign Up"
3. Complete Auth0 flow
4. Verify user creation in database

## Blockchain Setup

### 1. Ethereum Testnet

The application uses **Sepolia testnet** by default.

Get test ETH from:

- [Sepolia Faucet](https://sepoliafaucet.com/)
- [Alchemy Faucet](https://sepoliafaucet.com/)

## Background Jobs

### 1. Job Monitoring

- **Sidekiq Web UI**: http://localhost:3000/sidekiq
- **Job Logs**: `docker-compose logs -f sidekiq`
