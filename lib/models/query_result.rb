require "sequel"
require "models/query"
require "csv"
require "zlib"

class QueryResult < Sequel::Model
  one_to_one :query, key: :query_id
  unrestrict_primary_key

  def rows
    return [] unless results_path && File.file?(results_path)
    return [] unless rows_count < 1000
    Zlib::GzipReader.open(results_path) do |io|
      CSV.new(io).read
    end
  end

  def query_title
    query.title
  end

  def query_author
    query.author
  end
end
