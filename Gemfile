source "https://rubygems.org"
ruby "2.1.3"

gem "bundler"
gem "foreman", group: :development
gem "oj"

group :server do
  gem "escape"
  gem "sinatra"
  gem "thin"
  gem "uuid"
  gem "tzinfo"
end

group :worker do
  gem "activesupport", require: false
end

group :notifier do
  gem "pusher"
end
