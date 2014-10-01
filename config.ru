require "bundler"
Bundler.require :default, :server

require "omoikane/app"

use Rack::Static, urls: ["/css", "/images", "/js"], root: "public"
run Omoikane::App

# vim: ft=ruby
