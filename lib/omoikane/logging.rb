require "logger"

def logger
  LOGGER
end

LOGGER = Logger.new(STDOUT)
LOGGER.level = ENV["VERBOSE"] == "yes" ? Logger::DEBUG : Logger::INFO
LOGGER.formatter = lambda do |severity, datetime, progname, msg|
  "[#{"%-5s" % severity}] #{File.basename($0)}:#{Process.pid} - #{msg}\n"
end
