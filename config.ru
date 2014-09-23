require "omoikane/app"

use Rack::Static, urls: ["/stylesheets", "/images", "/js"], root: "public"
run Omoikane::App

# vim: ft=ruby
