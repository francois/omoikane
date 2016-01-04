source "https://rubygems.org"
ruby "2.2.4"

gem "bundler"
gem "dotenv"
gem "foreman", group: :development
gem "oj"
gem "sequel"

# Database Engine libraries, required by Sequel
# By default, we consider Postgres to be your go-to choice
gem "pg"
gem "sequel_pg", require: false # Recommended by Sequel

# gem "sqlite3"

group :server do
  gem "escape"
  gem "kramdown"
  gem "reform", "< 2.0.0"
  gem "sinatra"
  gem "thin"
  gem "tzinfo"
  gem "uuid"
  gem "zip"
end

group :worker do
  gem "activesupport", require: false
end

group :notifier do
  gem "pusher"
end

gem "rake",       groups: %w(development test)
