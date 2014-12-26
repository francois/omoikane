require "sequel"
require "models/query"
require "csv"
require "zlib"

class QueryResult < Sequel::Model
  one_to_one :query, key: :query_id

  def rows
    return [] unless results_path && File.file?(results_path)
    Zlib::GzipReader.open(results_path) do |io|
      CSV.new(io).read
    end
  end
end
