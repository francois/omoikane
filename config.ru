require "bundler"
Bundler.require :default, :server

require "omoikane/server"

use Rack::Static, urls: ["/css", "/images", "/js"], root: "public"
run Omoikane::Server

# vim: ft=ruby
