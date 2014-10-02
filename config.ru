require "bundler"
Bundler.require :default, :server

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "omoikane/server"

use Rack::Static, urls: ["/css", "/images", "/js"], root: "public"
run Omoikane::Server

# vim: ft=ruby
