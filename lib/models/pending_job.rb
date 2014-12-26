require "sequel"

class PendingJob < Sequel::Model
  unrestrict_primary_key

  def self.pending_query_ids
    ids = []

    db.transaction do
      ids = select_map(:query_id)
      filter(query_id: ids).delete
    end

    ids
  end
end
