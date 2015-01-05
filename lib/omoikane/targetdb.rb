require "omoikane/logging"

targetdb_url = ENV["OMOIKANE_TARGET_URL"]
raise "Missing OMOIKANE_TARGET_URL environment variable: can't connect to target Omoikane database" unless targetdb_url

ENV["QUIET"] = "yes" if ARGV.delete("--quiet")

TARGETDB = Sequel.connect(targetdb_url, logger: ENV["QUIET"] == "yes" ? nil : logger)
