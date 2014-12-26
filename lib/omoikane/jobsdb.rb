require "omoikane/logging"

jobsdb_url = ENV["OMOIKANE_DATABASE_URL"]
raise "Missing OMOIKANE_DATABASE_URL environment variable: can't connect to internal Omoikane database" unless jobsdb_url

DB = Sequel.connect(jobsdb_url, logger: logger)
Sequel::Model.plugin :tactical_eager_loading
