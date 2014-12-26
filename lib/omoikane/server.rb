require "cgi"
require "logger"
require "sinatra/base"

require "models/query"
require "models/pending_job"
require "models/project"
require "forms/job_form"
require "forms/query_form"
require "forms/project_form"

module Omoikane
  class Server < Sinatra::Base
    enable :logging

    enable :sessions
    set :session_secret, ENV["SESSION_SECRET"] if ENV["SESSION_SECRET"]

    set :views, File.expand_path("../../../views", __FILE__)

    def tz
      @tz ||= TZInfo::Timezone.get("America/Montreal")
    end

    get "/" do
      @jobs = Query.most_recent(25).
        map{|query| JobForm.new(query: query, state_changes: query.state_changes, results: query.results || QueryResult.new)}
      erb :queries
    end

    #
    # Queries
    #

    get "/queries/new" do
      @query = QueryForm.new(Query.new)
      @query.author = session[:author]
      erb :edit_query, layout: :layout
    end

    get "/query/:id/edit" do
      @query = QueryForm.new(Query[query_id: params[:id]])
      @query.author = session[:author]
      erb :edit_query, layout: :layout
    end

    #
    # Projects
    #

    get "/projects" do
      @projects = Project.most_recent(25).map{|project| ProjectForm.new(project: project, queries: project.queries)}
      erb :projects, layout: :layout
    end

    get "/projects/new" do
      @project = ProjectForm.new(project: Project.new(author: session[:author]), queries: [])
      erb :edit_project, layout: :layout
    end

    get "/project/:id/edit" do
      @project = OpenStruct.new(
        id: UUID.generate,
        title: "Netflix EOM",
        instructions: "Use this every first Monday of the month, to calculate Netflix's report. Fill in the parameters this way:\n\n* start_on: ...\n* end_on: ...\n",
        notes: "Internal notes for R&D people, not for people who will submit the project.",
        author: "pablo",
        persisted?: true,
        queries: [
          OpenStruct.new(title: "participants", sql: "SELECT count(DISTINCT persona_service_id) FROM ... WHERE market_id = 'france' AND daily_start_on BETWEEN :start_on AND :end_on"),
          OpenStruct.new(title: "interactions", sql: "SELECT count(*) FROM ... WHERE market_id = 'france' AND daily_start_on BETWEEN :start_on AND :end_on"),
        ]
      )
      erb :edit_project, layout: :layout
    end

    post "/projects" do
      @project = ProjectForm.new(project: Project.new, queries: [])
      if @project.validate(params[:project]) then
        @project.save
        redirect "/project/#{params[:id]}/edit"
      else
        erb :edit_project, layout: :layout
      end
    end

    post "/project/:id" do
      project = Project[params[:id]]
      @project = ProjectForm.new(project: project, queries: project.queries)
      if @project.validate(params[:project]) then
        @project.save
        redirect "/project/#{params[:id]}/edit"
      else
        erb :edit_project, layout: :layout
      end
    end

    get "/project/:id/queries/new" do
      @query = OpenStruct.new(
        persisted?: false,
        project_title: "Netflix EOM")
      erb :edit_project_query, layout: :layout
    end

    get "/project/:project_id/query/:id/edit" do
      @query = OpenStruct.new(
        persisted?: true,
        project_title: "Netflix EOM",
        title: "participants",
        sql: "SELECT\n    weekly_start_on\n  , count(DISTINCT persona_service_id || service_name)\nFROM show_interaction_bindings\nWHERE market_id = 'france'\n  AND daily_start_on BETWEEN :start_on AND :end_on\nGROUP BY weekly_start_on\nORDER BY weekly_start_on\n",
        notes: "Internal notes for the R&D specialist that works on this query")
      erb :edit_project_query, layout: :layout
    end

    post "/project/:project_id/queries" do
      # create
      redirect "/project/#{params[:project_id]}/edit"
    end

    post "/project/:project_id/query/:id" do
      # update
      redirect "/project/#{params[:project_id]}/edit"
    end

    delete "/project/:project_id/query/:id" do
      # delete
      redirect "/project/#{params[:project_id]}/edit"
    end

    get "/project/:id/runs/new" do
      @run = OpenStruct.new(
        id: UUID.generate,
        project_title: "Netflix EOM",
        project_instructions: "Use this every first Monday of the month, to calculate Netflix's report. Fill in the parameters this way:\n\n* start_on: ...\n* end_on: ...\n",
        project_notes: "Internal notes for R&D people, not for people who will submit the project.",
        subtitle: params[:run_id] ? "december 2014" : nil,
        submitter: params[:run_id] ? "cecile" : nil,
        persisted?: false,
        number_of_queries: 2,
        parameters: %w(start_on end_on start_at end_at category_name))
      erb :new_run, layout: :layout
    end

    post "/project/:id/runs" do
      # post
      redirect "/run/1234"
    end

    get "/run/:id" do
      @run = OpenStruct.new(
        id: UUID.generate,
        project_title: "Netflix EOM",
        project_instructions: "Use this every first Monday of the month, to calculate Netflix's report. Fill in the parameters this way:\n\n* start_on: ...\n* end_on: ...\n",
        project_notes: "Internal notes for R&D people, not for people who will submit the project.",
        subtitle: "december 2014",
        submitter: "cecile",
        persisted?: true,
        queries: [
          OpenStruct.new(submitted_at: "2014-12-23T19:33", current_state: "running", title: "participants", sql: "SELECT count(DISTINCT persona_service_id) FROM ... WHERE market_id = 'france' AND daily_start_on BETWEEN :start_on AND :end_on"),
          OpenStruct.new(submitted_at: "2014-12-23T19:33", current_state: "running", title: "interactions", sql: "SELECT count(*) FROM ... WHERE market_id = 'france' AND daily_start_on BETWEEN :start_on AND :end_on"),
        ],
        parameters: {start_on: "2014-11-09", end_on: "2014-12-27", start_at: "2014-11-01 07:00", end_at: "2014-12-31 08:00", category_name: "sports",})
      erb :run_status, layout: :layout
    end

    get "/download/:id" do
      # TODO: zip all results into a single file, then stream the resulting file
    end

    #
    # Jobs
    #

    post "/jobs" do
      query_id = UUID.generate
      @query = QueryForm.new(Query.new(query_id: query_id))
      if @query.validate(params[:query]) then
        Query.db.transaction do
          @query.save
          QueryState.create(query_id: query_id, updated_at: Time.now.utc, state: "submitted")
          PendingJob.create(query_id: query_id)
        end

        session[:author] = @query.author
        redirect "/job/#{query_id}"
      else
        erb :edit_query, layout: :layout
      end
    end

    # This route MUST come before /:id, or else Sinatra matches /:id and we fail to return anything
    get "/job/:id.csv" do
      query = QueryResult[query_id: params[:id]]
      halt 404 unless query

      headers "Content-Encoding" => "gzip"
      send_file query.results_path,
        disposition: :attachment,
        filename: "#{query.query_id}.csv",
        type: :csv
    end

    get "/job/:id" do
      query = Query[query_id: params[:id]]
      @job = JobForm.new(query: query, state_changes: query.state_changes, results: query.results || QueryResult.new)

      erb :job, layout: :layout
    end

    #
    # Search
    #

    get "/search" do
      erb :search_results, layout: :layout
    end

    not_found do
      erb :"404", layout: :layout
    end

    helpers do
      attr_reader :job, :project, :query, :run, :jobs

      def job_state_css_class(state)
        case state
        when "finished"   ; "fi-page"
        when "running"    ; "fi-loop"
        when "explaining" ; "fi-refresh"
        when "queued"     ; "fi-clock"
        when /^failed-/   ; "fi-asterisk"
        else              ; "fi-first-aid"
        end
      end

      def truncate(text, maxlength=30)
        text.length > maxlength ? text[0, maxlength] << "..." : text
      end

      def format_timestamp(timestamp)
        if Time.now.utc < (Date.today - 7).to_time then
          %Q(<span title="#{ tz.utc_to_local(timestamp).strftime("%Y-%m-%d %H:%M") }">#{ tz.utc_to_local(timestamp).strftime("%b %d, %H:%M") }</span>)
        elsif Time.now.utc < (Date.today - 1).to_time then
          %Q(<span title="#{ tz.utc_to_local(timestamp).strftime("%Y-%m-%d %H:%M") }">#{ tz.utc_to_local(timestamp).strftime("%a, %H:%M") }</span>)
        else
          %Q(<span title="#{ tz.utc_to_local(timestamp).strftime("%Y-%m-%d %H:%M") }">#{ time_ago_in_words(timestamp) }</span>)
        end
      end

      def h(str)
        CGI.escape_html(str.to_s)
      end

      def time_ago_in_words(timestamp)
        delta_seconds = Time.now.utc - timestamp

        case delta_seconds
        when 0...45                                ; "less than a minute"
        when 45...90                               ; "a minute"
        when 90...(30 * 60)                        ; "%d minute" % [ delta_seconds / 60 ]
        when (30 * 60)...(90 * 60)                 ; "an hour"
        when (90 * 60)...(24 * 60 * 60)            ; "%d hours" % [ delta_seconds / 3600 ]
        when (24 * 60 * 60)...(2 * 24 * 60 * 60) ; "a day"
        else
          "%d days" % [ delta_seconds / 3600 / 24 ]
        end
      end

      def format_elapsed(duration)
        "%.1f" % [ duration ]
      end

      def markdown(text)
        h(text).gsub("\n", "<br>")
      end

      def pusher_app_key
        ENV["PUSHER_APP_KEY"]
      end

      def input_type_from_parameter_name(parameter_name)
        case parameter_name
        when /_on$/
          "date"
        when /_at$/
          "datetime"
        else
          "text"
        end
      end
    end
  end
end
