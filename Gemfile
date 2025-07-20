source "https://rubygems.org"

ruby "3.3.4"

# Rails framework
gem "rails", "~> 7.2.2", ">= 7.2.2.1"

# Database
gem "pg", "~> 1.1"

# Server
gem "puma", ">= 5.0"

# Build JSON APIs with ease
gem "jbuilder"

# Redis for caching and background jobs
gem "redis", ">= 4.0.1"

# Background jobs
gem "sidekiq"
gem "sidekiq-cron"

# Authentication
gem "omniauth"
gem "omniauth-auth0"
gem "omniauth-rails_csrf_protection"

# Blockchain gems
gem "eth"
gem "httparty"

# CORS for handling Cross-Origin Resource Sharing
gem "rack-cors"

# Environment variables
gem "dotenv-rails"

# JSON Web Token
gem "jwt"

# Active Model has_secure_password for encryption
gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants
gem "image_processing", "~> 1.2"

group :development, :test do
  # Debugging
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Testing
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "simplecov", require: false
  gem "minitest-reporters"

  # Static analysis for security vulnerabilities
  gem "brakeman", require: false

  # Ruby styling
  gem "rubocop-rails-omakase", require: false
end

group :development do
  # Preview emails in browser
  gem "web-console"
end

group :test do
  # Testing matchers
  gem "shoulda-matchers"

  # Record HTTP interactions for tests
  gem "vcr"
  gem "webmock"

  # Mocking and stubbing
  gem "mocha"
end
