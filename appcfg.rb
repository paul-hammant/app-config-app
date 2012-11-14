# Copyright (c) 2012>, Paul Hammant (portions Dan Doezema)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met: 
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer. 
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution. 
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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

    before do
      redirect '/login' unless session[:authenticated]
    end

    after do
      redirect params[:return_to] if params[:return_to] and params[:return_to].start_with? '/'
    end

    get '/' do
      sync
      forms = {}
      Dir.glob "#{working_copy}/**/*.html" do |file|
        file = file.gsub /(^#{Regexp.escape working_copy}\/)/, ''
        env = file[/^[^\/]+/];
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

    get '/form/*' do
      json_resource = params[:splat][0].sub /html$/, 'json'
      js_resource = path_to params[:splat][0].sub /html$/, 'js'
      html_resource = path_to params[:splat][0]
      erb :form, locals: {
          cfg_form: json_resource,
          form: File.open(html_resource) {|file| file.read},
          js: File.exists?(js_resource) ? File.open(js_resource) {|file| file.read} : '',
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
      elsif extension == 'html'
        content_type 'text/html', :charset => 'utf-8'
      end
      File.open resource, 'r' do |file|
        file.read
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

  class LoginApp < BaseApp
    before do
      redirect '/' if session[:authenticated]
    end

    get '/' do
      erb :login
    end

    post '/' do
      message, code = p4sync params[:username], params[:password]
      if code == 0
        session[:authenticated] = true
        session[:username] = params[:username]
        session[:password] = params[:password]
        redirect '/'
      elsif message.include? "Client '#{client_name params[:username]}' unknown" or message.include? "Perforce password (P4PASSWD) invalid or unset."
        request.logger.error message
        "The administrator needs to configure client '#{client_name params[:username]}' for user '#{params[:username]}'"
      elsif message.include? 'command not found'
        request.logger.error message
        'p4 does not appear to be installed'
      else
        request.logger.error message
        'An unknown error occurred'
      end
    end
  end

  class ServiceApp < BaseApp
    def self.new(*)
      app = Rack::Auth::Digest::MD5.new(super) do |username|
        Thread.current[:username] = username
        Thread.current[:password] = (YAML.load_file 'passwords.yaml')[username]
      end
      app.realm = 'App-Config-App Service'
      app.opaque = Digest::MD5.hexdigest (0...50).map{('a'..'z').to_a[rand 26]}.join
      app
    end

    before do
      session[:authenticated] = false
      [:username, :password].each do |key|
        session[key] = Thread.current[key]
        Thread.current[key] = nil
      end
    end

    get '/*' do
      sync
      resource_uri = params[:splat][0]
      resource = path_to resource_uri
      extension = extension_of resource
      File.open (resource.sub /\.(.+)$/, '.json'), 'r' do |file|
        contents = file.read
        if extension == 'json'
          content_type 'application/json'
          contents
        elsif extension == 'md5'
          Digest::MD5.hexdigest contents
        else
          raise 'Illegal resource type'
        end
      end
    end
  end
end
