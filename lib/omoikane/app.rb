require "cgi"
require "sinatra/base"
require "omoikane/job_mapper"
require "omoikane/jobs_controller"

module Omoikane
  class App < Sinatra::Base
    enable :logging
    set :views, File.expand_path("../../../views", __FILE__)

    configure do
      JOBSDIR = ENV["JOBSDIR"]
      raise "JOBSDIR not passed on command line: won't continue" unless JOBSDIR
      raise "JOBSDIR is set to #{JOBSDIR.inspect}, but is not a directory: won't continue" unless File.directory?(JOBSDIR)
    end

    def mapper
      @mapper ||= Omoikane::JobMapper.new
    end

    def controller
      @controller ||= Omoikane::JobsController.new(JOBSDIR, mapper)
    end

    def tz
      @tz ||= TZInfo::Timezone.get("America/Montreal")
    end

    get "/" do
      erb :home, layout: :layout
    end

    get "/queries/new" do
      @job = Job.new(author: session[:author] || "", query: "", title: "")
      erb :editor, layout: :layout
    end

    post "/queries" do
      query = params[:query]
      id = UUID.generate
      job = Job.new(title: query[:title], author: query[:author], query: query[:sql], id: id)
      controller.submit_job(id, job)
      redirect "/query/#{id}"
    end

    get "/query/:id" do
      @job = controller.job_status(params[:id])
      erb :status, layout: :layout
    end

    get "/query/:id/edit" do
      @job = controller.job_status(params[:id])
      erb :editor, layout: :layout
    end

    post "/query/:id" do
      query = params[:query]
      id = params[:id]
      job = Job.new(title: query[:title], author: query[:author], query: query[:sql], id: id)
      controller.submit_job(id, job)
      redirect "/query/#{id}"
    end

    helpers do
      attr_reader :job

      def job_state_css_class(state)
        case state
        when "finished" ; "fi-folder"
        when "running"  ; "fi-refresh"
        when "queued"   ; "fi-clock"
        else            ; "fi-first-aid"
        end
      end

      def truncate(text, maxlength=30)
        text.length > maxlength ? text[0, maxlength] << "..." : text
      end

      def format_timestamp(timestamp)
        %Q(<span title="#{ tz.utc_to_local(timestamp).strftime("%Y-%m-%d %H:%M") }">#{ tz.utc_to_local(timestamp).strftime("%H:%M") }</span>)
      end

      def h(str)
        CGI.escape_html(str.to_s)
      end

      def vm
        @vm ||= OpenStruct.new(jobs: controller.jobs.first(25))
      end
    end
  end
end
