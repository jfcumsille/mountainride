source 'https://rubygems.org'

# Use main development branch of Rails
gem 'rails', github: 'rails/rails', branch: 'main'
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem 'propshaft'
# Use postgresql as the database for Active Record
gem 'pg', '~> 1.6'
# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '>= 5.0'
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem 'importmap-rails'
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails'
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'stimulus-rails'
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem 'tailwindcss-rails', '~> 2.7'
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem 'jbuilder'

# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem 'solid_cable'
gem 'solid_cache'
gem 'solid_queue'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem 'kamal', require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem 'thruster', require: false

# gem "image_processing", "~> 1.2"

gem 'activeadmin', '4.0.0.beta17'
gem 'devise'
gem 'pundit'

gem 'active_model_serializers'
gem 'responders'

group :development, :test do
  gem 'factory_bot_rails'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rspec'
  gem 'rspec-rails'
  gem 'rubocop', '~> 1.68'
  gem 'rubocop-performance'
  gem 'rubocop-rails', '~> 2.27'
  gem 'rubocop-rspec', '~> 2.23', '>= 2.23.2'

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem 'brakeman', require: false
end

group :development do
  gem 'annotate'
  gem 'ruby-lsp-rails'
end

group :test do
  gem 'database_cleaner-active_record'
  gem 'rspec_junit_formatter', '0.6.0'
  gem 'shoulda-matchers', '~> 6.4', require: false
  gem 'test-prof', '~> 1.0'
end
