require "time"

module Omoikane
  class Job
    def initialize(attributes)
      @attributes = attributes.dup
    end

    attr_reader :attributes

    def new_record?
      !attributes.has_key?(:id)
    end

    def id
      attributes.fetch(:id)
    end

    def current_state
      attributes.fetch(:current_state)
    end

    def updated_at
      changes = attributes.fetch(:state_changes, [])
      last_change = changes.last
      last_change ? Time.parse(last_change.first).utc : Time.now.utc
    end

    def finished?
      current_state == "finished"
    end

    def elapsed_seconds
      changes = attributes.fetch(:state_changes, [])
      started_at  = changes.first
      finished_at = changes.last
      if started_at && finished_at then
        if started_at == finished_at then
          # No state change, so we can use "now"
          Time.now.utc - Time.parse(started_at.first).utc
        else
          Time.parse(finished_at.first).utc - Time.parse(started_at.first).utc
        end
      else
        # This seems like an error, so 0 is a safe value
        0
      end
    end

    def has_results?
      current_state == "finished"
    end

    def author
      attributes.fetch(:author)
    end

    def title
      attributes[:title] || attributes.fetch(:query).gsub(/[\r\n]/, " ").gsub("  ", " ")
    end

    def rows_count
      attributes.fetch(:rows_count)
    end

    def query
      attributes.fetch(:query)
    end

    def query_plan
      attributes.fetch(:explain_stdout)
    end

    def plan_error
      attributes.fetch(:explain_stderr)
    end

    def query_error
      attributes.fetch(:run_stderr)
    end

    def columns
      attributes.fetch(:columns)
    end

    def results
      attributes.fetch(:results)
    end
  end
end
