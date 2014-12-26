require "omoikane/logging"

targetdb_url = ENV["OMOIKANE_TARGET_URL"]
raise "Missing OMOIKANE_TARGET_URL environment variable: can't connect to target Omoikane database" unless targetdb_url

TARGETDB = Sequel.connect(targetdb_url, logger: logger)
