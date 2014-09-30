source "https://rubygems.org"
ruby "2.1.3"

gem "foreman", group: :unused
gem "oj"

group :server do
  gem "sinatra"
  gem "thin"
  gem "uuid"
end

group :worker do
  gem "activesupport", require: false
end
