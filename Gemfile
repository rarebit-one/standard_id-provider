source "https://rubygems.org"

gemspec

gem "puma"

gem "sqlite3"

gem "propshaft"

gem "standard_id", path: "../standard_id" unless ENV["CI"]

group :development, :test do
  gem "rspec-rails", "~> 8.0"
  gem "shoulda-matchers", "~> 7.0"
end

# Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
gem "rubocop-rails-omakase", require: false
gem "brakeman", require: false
gem "bundler-audit", require: false
