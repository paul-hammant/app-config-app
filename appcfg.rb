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

    use Rack::Auth::Basic, 'Protected Area' do |username, password|
      _, code = p4sync username, password
      if code == 0
        Thread.current[:username] = username
        Thread.current[:password] = password
        true
      else
        false
      end
    end

    before do
      [:username, :password].each do |key|
        session[key] = Thread.current[key]
        Thread.current[key] = nil
      end
      session[:authenticated] = true
    end

    after do
      redirect params[:return_to] if params[:return_to] and params[:return_to].start_with? '/'
    end

    get '/' do
      sync
      erb :config_forms, locals: {
          forms: (directory_hash working_copy),
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

    post '/revert/*' do
      resource = params[:splat][0]
      try p4revert path_to resource
      erb :revert, layout: !request.xhr?, locals: {
          filename: resource
      }
    end

    get '/revs/*' do
      content_type 'application/json'
      message = try p4filelog path_to params[:splat][0]
      JSON.generate message.scan(/#(\d+) change/)
    end

    post '/sync' do
      message, code = p4sync
      erb :sync, layout: !request.xhr?, locals: {
          message: message,
          code: code
      }
    end

    get '/promote' do
      erb :promote, layout: !request.xhr?
    end

    post '/promote/:mapping' do
      content_type 'application/json'
      mapping = params[:mapping]
      reverse = !params[:reverse].nil?
      source, destination = reverse ? (mapping.split '-').reverse! : (mapping.split '-')
      result = {success: true, message: (params[:dryRun] ? 'Dry run successful' : 'Promotion successful, please check pending changes and commit')}
      if has_changes path_to source + '/...' or has_changes path_to destination + '/...'
        result = {success: false, message: 'Cannot promote changes from ' + source + ' to '+ destination + ': there are pending changes'}
      else
        message = try p4integrate mapping, reverse
        if message.include? 'No permission for operation'
          result = {success: false, message: 'You are not allowed to promote changes from ' + source + ' to '+ destination}
        elsif message.include? 'already integrated'
          result = {success: true, message: 'There are no changes to promote'}
        else
          op = try p4resolve destination, (params[:recordOnly]? 'at' : 'am')
          /(\d+) conflicting/.match (op)
          conflicts = Regexp.last_match(1)
          if conflicts != '0'
            result = {success: false, message: 'Unable to promote changes: there are conflicts\n\nPerforce output:\n' + op}
          end
          try p4revert path_to destination + '/...'
        end
      end
      if params[:dryRun]
        try p4revert path_to destination + '/...'
      end
      promote_value = result
      JSON.generate promote_value
    end

    get '/change_mappings.json' do
      mappings = (try p4branches).split(' ').select { |x| x.include? '-' }
      array = []
      mappings.each do |x|
        source, destination = x.split('-')
        next unless (File.exists? path_to source) and (File.exists? path_to destination)
        array << {
            from: source,
            to: destination,
            from_has_changes: (has_changes path_to source + '/...'),
            to_has_changes: (has_changes path_to destination + '/...'),
        }
      end
      array.to_json
    end

    get '/*.html' do
      sync
      resource = path_to params[:splat][0] + '.html'
      json_resource = params[:splat][0] + '.json'
      js_resource = path_to params[:splat][0] + '.js'
      erb :form, locals: {
          cfg_form: json_resource,
          form: File.open(resource) { |file| file.read },
          js: File.exists?(js_resource) ? File.open(js_resource) { |file| file.read } : ''
      }
    end

    get '/*.json' do
      sync
      content_type (/MSIE|Firefox|Chrome|Safari|Opera/i =~ request.user_agent) ? 'text/plain' : 'application/json'
      File.open(path_to params[:splat][0] + '.json') { |file| file.read }
    end

    get '/*.md5' do
      sync
      content_type 'text/plain'
      File.open(path_to params[:splat][0] + '.json') { |file| Digest::MD5.hexdigest file.read }
    end

    get '/*.js' do
      sync
      content_type 'text/javascript'
      File.open(path_to params[:splat][0]) { |file| file.read }
    end

    get '/*.changed' do
      sync
      content_type 'text/plain'
      (diffs_for path_to params[:splat][0] + '.json') == '' ? 'false' : 'true'
    end

    get '/*.diffs' do
      resource_short = params[:splat][0] + '.json'
      resource = path_to resource_short
      erb :diffs, layout: !request.xhr?, locals: {
          filename: resource_short,
          diffs: (diffs_for resource),
      }
    end

    post '/*.json' do
      resource = path_to params[:splat][0] + '.json'
      try p4edit resource
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
      status flash[:status] || 500
      erb :error, locals: {
          message: flash[:error]
      }
    end
  end
end
