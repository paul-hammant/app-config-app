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
  enable :sessions

  before do
     redirect '/login' unless request.path_info == '/login' or session[:authenticated]
  end

  get '/login' do
    haml :login
  end

  post '/login' do
    client = params[:username] + 'Client'
    result = %x[p4 -u #{params[:username]} -P #{params[:password]} -c #{client} sync 2>&1]
    if $? == 0
      session[:authenticated] = true
      session[:username] = params[:username]
      session[:password] = params[:password]
      session[:client] = client
      redirect '/'
    elsif result.include? "Client '#{client}' unknown" or result.include? "Perforce password (P4PASSWD) invalid or unset."
      "The administrator needs to configure client '#{client}' for user '#{params[:username]}'"
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
    contents = %x[git push | aha --no-header]
  end

  post '/commit' do
    cmd = "git commit -am '" + params[:message] + "' | aha --no-header"
    content_type 'text/html', :charset => 'utf-8'
    contents = %x[#{cmd}]
  end

  post '/pull' do
    content_type 'text/html', :charset => 'utf-8'
    contents = %x[git pull | aha --no-header]
  end

  get '/' do
    redirect "index.html"
  end

  get '/logout' do
    session.clear
    redirect '/'
  end

  get '/*' do
    resource = params[:splat][0]
    file = File.open(resource, 'r')
    file.read
  end

  post '/*' do
    resource = params[:splat][0]
    FileUtils.mkdir_p(File.dirname(resource))
    File.open(resource, 'w+') do |file|
      file.write(request.body.read)
    end
    contents = %x[jshon -ISF ./#{resource}]
  end
end


