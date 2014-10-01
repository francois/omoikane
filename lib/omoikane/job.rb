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

    def has_results?
      current_state == "finished"
    end

    def author
      attributes.fetch(:author)
    end

    def title
      attributes[:title] || attributes.fetch(:query).gsub("\n", " ")
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
