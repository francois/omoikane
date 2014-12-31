require "cgi"
require "logger"
require "sinatra/base"
require "zip/zip"

require "models/query"
require "models/pending_job"
require "models/project"
require "models/run"
require "models/run_query"
require "forms/job_form"
require "forms/query_form"
require "forms/project_form"
require "forms/project_query_form"
require "forms/run_form"
require "forms/run_status_form"

module Omoikane
  class Server < Sinatra::Base
    enable :logging
    enable :method_override

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
      @projects = Project.most_recent(25).map{|project| ProjectForm.new(project)}
      erb :projects, layout: :layout
    end

    get "/projects/new" do
      @form = ProjectForm.new(Project.new(author: session[:author]))
      erb :edit_project, layout: :layout
    end

    get "/project/:id/edit" do
      @form = ProjectForm.new(Project[params[:id]])
      erb :edit_project, layout: :layout
    end

    post "/projects" do
      @form = ProjectForm.new(Project.new)
      if @form.validate(params[:project]) then
        @form.project_id = UUID.generate
        @form.save
        redirect "/project/#{@form.project_id}/edit"
      else
        erb :edit_project, layout: :layout
      end
    end

    post "/project/:id" do
      project = Project[params[:id]]
      @form = ProjectForm.new(project)
      if @form.validate(params[:project]) then
        @form.save
        redirect "/project/#{params[:id]}/edit"
      else
        erb :edit_project, layout: :layout
      end
    end

    get "/project/:id/queries/new" do
      @form = ProjectQueryForm.new(ProjectQuery.new(project: Project[params[:id]]))
      erb :edit_project_query, layout: :layout
    end

    get "/project/:project_id/query/:id/edit" do
      @form = ProjectQueryForm.new(ProjectQuery[query_id: params[:id]])
      erb :edit_project_query, layout: :layout
    end

    post "/project/:project_id/queries" do
      if project = Project[params[:project_id]] then
        @form = ProjectQueryForm.new(ProjectQuery.new(project: Project[params[:project_id]]))
        if @form.validate(params[:query]) then
          @form.query_id = UUID.generate
          @form.save

          redirect "/project/#{@form.project_id}/edit"
        else
          erb :edit_project_query, layout: :layout
        end
      else
        halt :not_found
      end
    end

    post "/project/:project_id/query/:id" do
      if query = ProjectQuery[query_id: params[:id], project_id: params[:project_id]] then
        @form = ProjectQueryForm.new(query)
        if @form.validate(params[:query]) then
          @form.save
          redirect "/project/#{@form.project_id}/edit"
        else
          erb :edit_project_query, layout: :layout
        end
      else
        halt :not_found
      end
    end

    delete "/project/:project_id/query/:id" do
      if query = ProjectQuery[query_id: params[:id], project_id: params[:project_id]] then
        query.delete
        redirect "/project/#{query.project_id}/edit"
      else
        halt :not_found
      end
    end

    #
    # Runs
    #

    get "/project/:id/runs/new" do
      @form = RunForm.new(Run.new(submitter: session[:author], project: Project[params[:id]]))
      erb :new_run, layout: :layout
    end

    post "/project/:id/runs" do
      project = Project[params[:id]]
      run     = Run.new(project: project)
      @form   = RunForm.new(run)
      if @form.validate(params[:run]) then
        Sequel::Model.db.transaction do
          @form.save do |validated_params|
            # The equivalent of ActiveRecord's attr_accessible
            acceptable_params = @form.build_default_parameters.keys.map(&:to_s)

            run.subtitle     = validated_params.fetch(:subtitle)
            run.submitter    = validated_params.fetch(:submitter)
            run.parameters   = Oj.dump(params[:run].fetch(:parameters, {}).select{|name, _| acceptable_params.include?(name.to_s)})
            run.save
          end

          runparams = Oj.load(run.parameters, symbol_keys: true)

          run.remove_all_queries
          project.queries.each do |query|
            job = Query.create(query_id: UUID.generate, title: "#{query.title} (#{project.title} / #{run.subtitle})", author: @form.submitter, sql: TARGETDB[query.sql, runparams].sql)
            RunQuery.create(run_id: run.run_id, project_id: query.project_id, query_id: query.query_id, job_id: job.query_id)
            PendingJob.create(query_id: job.query_id)
          end
        end

        redirect "/run/#{run.run_id}"
      else
        erb :new_run, layout: :layout
      end
    end

    get "/runs" do
      # TODO: implement list of runs
      erb :runs, layout: :layout
    end

    get "/run/:id" do
      @form = RunStatusForm.new(Run[params[:id]])
      erb :run_status, layout: :layout
    end

    get "/download/:id.:format" do
      run = Run[params[:id]]
      halt :not_found unless run

      case params[:format]
      when "zip"
        filename = File.join(ENV.fetch("TMPDIR", "/tmp"), "#{UUID.generate}.zip")
        Zip::ZipFile.open(filename, Zip::ZipFile::CREATE) do |zipfile|
          run.results.each do |result|
            slug = result.query.title.downcase.gsub(/\W+/, "-").sub(/^-|-$/, "")
            zipfile.get_output_stream("#{slug}.#{result.query.query_id}.csv") do |io|
              # Decompress the data, in order to recompress in Zip format later
              data = Zlib::GzipReader.open(result.results_path) do |input|
                input.read
              end

              io.write(data)
            end
          end
        end

        slug = "#{run.project.title}-#{run.subtitle}".downcase.gsub(/\W+/, "-").sub(/^-|-$/, "")
        send_file filename,
          disposition: :attachment,
          filename: "#{slug}.zip",
          type: "application/zip"
      else
        # TODO: use a better way to say not acceptable
        halt 406, "Content Not Acceptable"
      end
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
      attr_reader :job, :project, :query, :run, :jobs, :projects, :form

      def job_state_css_class(state)
        case state
        when "finished"       ; "fi-page"
        when "running"        ; "fi-loop"
        when "explaining"     ; "fi-refresh"
        when /started|queued/ ; "fi-clock"
        when /^failed-/       ; "fi-asterisk"
        else                  ; "fi-first-aid"
        end
      end

      def truncate(text, maxlength=30)
        text.length > maxlength ? text[0, maxlength] << "..." : text
      end

      def format_timestamp(timestamp)
        if timestamp < (Date.today - 7).to_time then
          %Q(<span class="timestamp" title="#{ tz.utc_to_local(timestamp).strftime("%Y-%m-%d %H:%M") }">#{ tz.utc_to_local(timestamp).strftime("%b %d, %H:%M") }</span>)
        elsif timestamp < (Date.today - 1).to_time then
          %Q(<span class="timestamp" title="#{ tz.utc_to_local(timestamp).strftime("%Y-%m-%d %H:%M") }">#{ tz.utc_to_local(timestamp).strftime("%a, %H:%M") }</span>)
        else
          %Q(<span class="timestamp" title="#{ tz.utc_to_local(timestamp).strftime("%Y-%m-%d %H:%M") }">#{ time_ago_in_words(timestamp) } ago</span>)
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
        Kramdown::Document.new(text).to_html
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

      def form_errors_if_any(form)
        return if form && form.errors && form.errors.empty?
        erb :_form_errors, locals: {form: form}
      end
    end
  end
end
