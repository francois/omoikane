require "bundler"
Bundler.require :default, :server

require "logger"

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "omoikane/jobsdb"
Sequel::Model.db = DB

require "omoikane/targetdb"
require "omoikane/server"

use Rack::Static, urls: ["/css", "/images", "/js"], root: "public"
run Omoikane::Server

# vim: ft=ruby
