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
require 'haml'
require 'sinatra'
require 'json'

class App < Sinatra::Application
  configure do
    enable :sessions
  end

  before do
     redirect '/login' unless request.path_info == '/login' or session[:authenticated]
  end

  get '/login' do
    haml :login
  end

  post '/login' do
    message, code = sync params[:username], params[:password]
    if code == 0
      session[:authenticated] = true
      session[:username] = params[:username]
      session[:password] = params[:password]
      redirect '/'
    elsif message.include? "Client '#{client_name params[:username]}' unknown" or message.include? "Perforce password (P4PASSWD) invalid or unset."
      "The administrator needs to configure client '#{client_name params[:username]}' for user '#{params[:username]}'"
    else
      "An unknown error occurred"
    end
  end

  get '/diffs' do
    content_type 'text/html', :charset => 'utf-8'
    content = %x[git diff --word-diff=color | aha --no-header | egrep '<span style="color:(red|green);">']
    content.gsub /\n/, '<br/>'
  end

  post '/push' do
    content_type 'text/html', :charset => 'utf-8'
    %x[git push | aha --no-header]
  end

  post '/commit' do
    cmd = "git commit -am '" + params[:message] + "' | aha --no-header"
    content_type 'text/html', :charset => 'utf-8'
    %x[#{cmd}]
  end

  post '/pull' do
    content_type 'text/html', :charset => 'utf-8'
    %x[git pull | aha --no-header]
  end

  get '/' do
    redirect "index.html"
  end

  get '/logout' do
    session.clear
    redirect '/'
  end

  get '/*' do
    try_sync
    resource = path_to params[:splat][0]
    extension = extension_of resource
    if extension == 'json'
      content_type 'application/json'
    elsif extension == 'html'
      content_type 'text/html', :charset => 'utf-8'
    end
    file = File.open(resource, 'r')
    content = file.read
    file.close
    content
  end

  post '/*' do
    resource = path_to params[:splat][0]
    try_sync
    if File.exists? resource
      try_edit resource
    else
      FileUtils.mkdir_p(File.dirname(resource))
      try_add resource
    end
    File.open(resource, 'w+') do |file|
      file.write(request.body.read)
    end
    if extension_of(resource) == 'json'
      %x[jshon -ISF #{resource}]
    end
  end

  def add(resource, username = nil, password = nil)
    [%x[#{p4 username, password} add #{clean resource} 2>&1], $?]
  end

  def edit(resource, username = nil, password = nil)
    [%x[#{p4 username, password} edit #{clean resource} 2>&1], $?]
  end

  def clean(resource)
    if resource.include? "'"
      raise 'Resource contains invalid characters'
    end
    "'#{resource}'"
  end

  def p4(username = nil, password = nil)
    username ||= session[:username]
    password ||= session[:password]
    if /[^\w+\-\.]/.match(username) or /[^\w+\-\.]/.match(password)
      raise 'Illegal characters in username or password'
    end
    "p4 -u #{username} -P #{password} -c #{client_name username}"
  end

  def sync(username = nil, password = nil)
    [%x[#{p4 username, password} sync 2>&1], $?]
  end

  def path_to(resource, username = nil)
    username ||= session[:username]
    File.join(File.dirname(__FILE__), 'wc', username, resource)
  end

  def client_name(username = nil)
    username ||= session[:username]
    username + 'Client'
  end

  def extension_of(resource)
    return resource.split('.').pop
  end

  def try_edit(resource, username = nil, password = nil)
    _, code = edit resource, username, password
    if code != 0
      redirect '/error'
    end
  end

  def try_add(resource, username = nil, password = nil)
    _, code = add resource, username, password
    if code != 0
      redirect '/error'
    end
  end

  def try_sync(username = nil, password = nil)
    _, code = sync username, password
    if code != 0
      redirect '/error'
    end
  end
end


