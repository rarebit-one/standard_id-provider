source "https://rubygems.org"

gemspec

gem "puma"
gem "sqlite3"
gem "propshaft"

# Use local standard_id for development
gem "standard_id", path: "../standard_id"

group :development, :test do
  gem "rspec-rails", "~> 8.0"
  gem "shoulda-matchers", "~> 7.0"
end

gem "rubocop-rails-omakase", require: false
