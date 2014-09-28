require "time"

module Omoikane
  class Job
    def initialize(attributes)
      @attributes = attributes.dup
    end

    attr_reader :attributes

    def id
      attributes.fetch(:id)
    end

    def current_state
      attributes.fetch(:current_status)
    end

    def updated_at
      changes = attributes.fetch(:state_changes, [])
      last_change = changes.last
      last_change ? Time.parse(last_change.first).utc : Time.now.utc
    end

    def author
      attributes.fetch(:author)
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
  end
end
