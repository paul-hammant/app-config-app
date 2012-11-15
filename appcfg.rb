require 'rubygems'
require 'sinatra'
require 'sinatra/contrib'
require 'json'
require 'rack/flash'
require 'singleton'
require 'yaml'
require_relative 'helpers'

module AppCfg
  class BaseApp < Sinatra::Application
    helpers AppCfg::Helpers
    use Rack::Flash

    include Rack::Utils
    alias_method :h, :escape_html

    configure do
      enable :sessions
    end
  end

  class App < BaseApp
    extend Helpers

    use Rack::Auth::Basic, "Protected Area" do |username, password|
      message, code = p4sync username, password
      if code == 0
        Thread.current[:username] = username
        Thread.current[:password] = password
        true
      elsif message.include? "Client '#{client_name username}' unknown" or message.include? "Perforce password (P4PASSWD) invalid or unset."
        flash[:error] = "The administrator needs to configure client '#{client_name username}' for user '#{username}'"
        redirect '/error'
      elsif message.include? 'command not found'
        flash[:error] = 'p4 does not appear to be installed'
        redirect '/error'
      else
        flash[:error] = 'An unknown error occurred'
        redirect '/error'
      end
    end

    before do
      [:username, :password].each do |key|
        session[key] = Thread.current[key]
        Thread.current[key] = nil
      end
    end

    after do
      redirect params[:return_to] if params[:return_to] and params[:return_to].start_with? '/'
    end

    get '/' do
      sync
      forms = {}
      Dir.glob "#{working_copy}/**/*.html" do |file|
        file = file.gsub /(^#{Regexp.escape working_copy}\/)/, ''
        env = file[/^[^\/]+/] || '.'
        forms[env] ||= []
        forms[env].push file.gsub /^#{env}\//, ''
      end
      erb :config_forms, locals: {
          forms: forms,
      }
    end

    get '/changes' do
      erb :changes, locals: {
          edited_files: (parse_diffs try p4diff)
      }
    end

    post '/commit' do
      message = request.xhr? ? (JSON.parse request.body.read)['message'] : request[:message]
      raise 'No message entered' if message.nil? or message.length == 0
      try p4commit message
    end

    get '/diffs/*' do
      resource_short = params[:splat][0]
      resource = path_to resource_short
      erb :diffs, :layout => !request.xhr?, locals: {
          filename: resource_short,
          diffs: (diffs_for resource),
      }
    end

    get '/logout' do
      if params[:confirm].nil? and (parse_diffs p4diff[0]).length > 0
        erb :confirm_logout
      else
        session.clear
        redirect '/'
      end
    end

    post '/push' do
      content_type 'text/html', :charset => 'utf-8'
      %x[git push | aha --no-header]
    end

    post '/revert/*' do
      resource = params[:splat][0]
      try p4revert path_to resource
      erb :revert, :layout => !request.xhr?, locals: {
          filename: resource
      }
    end

    post '/sync' do
      message, code = p4sync
      erb :sync, :layout => !request.xhr?, locals: {
          message: message,
          code: code
      }
    end

    get '/*' do
      sync
      resource_uri = params[:splat][0]
      resource = path_to resource_uri
      extension = extension_of resource
      if extension == 'json'
        content_type 'application/json'
        File.open(resource) {|file| file.read}
      elsif extension == 'md5'
        content_type 'text/plain'
        File.open(resource.sub /md5$/, 'json') {|file| Digest::MD5.hexdigest file.read}
      elsif extension == 'js'
        content_type 'text/javascript'
        File.open(resource) {|file| file.read}
      elsif extension == 'html'
        json_resource = resource_uri.sub /html$/, 'json'
        js_resource = path_to resource_uri.sub /html$/, 'js'
        erb :form, locals: {
            cfg_form: json_resource,
            form: File.open(resource) {|file| file.read},
            js: File.exists?(js_resource) ? File.open(js_resource) {|file| file.read} : '',
        }
      end
    end

    post '/*' do
      resource = path_to params[:splat][0]
      if (extension_of resource) != 'json'
        raise 'Only JSON files may be edited'
      end
      if File.exists? resource
        try p4edit resource
      else
        FileUtils.mkdir_p File.dirname resource
        FileUtils.touch resource
        try p4add resource
      end
      File.open resource, 'w+' do |file|
        file.write JSON.pretty_generate JSON.parse request.body.read
      end
      204
    end
  end

  class ErrorApp < BaseApp
    configure do
      enable :sessions
    end

    before do
      flash[:error] ||= 'No error message'
    end

    get '/' do
      erb :error, locals: {
          message: flash[:error]
      }
    end
  end
end
