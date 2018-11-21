source 'https://rubygems.org'

ruby "2.5.1"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 5.2.1"
# Use mysql2 as the database for Active Record
gem "mysql2"
# Use Puma as the app server
gem "puma", "~> 3.7"
# Use SCSS for stylesheets
gem "sassc-rails", "~> 2.0"
# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 1.3.0"

# Use CoffeeScript for .coffee assets and views
gem "coffee-rails", "~> 4.2"

gem "ims-lti"
# rest client
gem "rest-client"

gem "bootstrap-sass", "~> 3.3.6"
gem "jquery-rails"
gem "jquery-ui-rails"

# more awesome logging
gem "activerecord-session_store"
gem "awesome_print"
gem "rails_semantic_logger"

# Auditing
gem "paper_trail"

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug"
  gem "pry-byebug"
  # Adds support for Capybara system testing and selenium driver
  gem "capybara", "~> 2.13"
  gem "rspec-rails" # this needs to be available in development so that the rails generators can use rspec rather than test-unit
  gem "selenium-webdriver"
  gem "simplecov", { require: false }
  # factory girl with rails support
  gem "factory_bot_rails"
  # rails-controller-testing
  gem "rails-controller-testing"
end

group :development do
  gem "listen", ">= 3.0.5", "< 3.2"
  gem "web-console", ">= 3.3.0"
end

# Testing and style checking gems.
group :test do
  gem "faker"
  gem "rspec"
  gem "rubocop", { require: false }
end

# Install organisation-specific gems
Dir.glob(File.join(File.dirname(__FILE__), "gemfiles", "Gemfile.*")) do |gemfile|
  eval(IO.read(gemfile), binding)
end
