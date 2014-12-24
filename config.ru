require "bundler"
Bundler.require :default, :server

require "logger"

DB = Sequel.connect(ENV.fetch("OMOIKANE_DATABASE_URL"), logger: Logger.new(STDERR))

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "omoikane/server"

use Rack::Static, urls: ["/css", "/images", "/js"], root: "public"
run Omoikane::Server

# vim: ft=ruby
