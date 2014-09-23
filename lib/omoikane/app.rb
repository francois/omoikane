require "sinatra/base"

module Omoikane
  class App < Sinatra::Base
    enable :logging

    get "/" do
      File.read("public/index.html")
    end
  end
end
