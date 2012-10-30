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
require 'rack/flash'

class App < Sinatra::Application
  use Rack::Flash

  configure do
    enable :sessions
  end

  before do
    redirect '/login' unless request.path_info == '/login' or session[:authenticated]
    try_p4sync
  end

  get '/' do
    redirect 'index.html'
  end

  get '/changes' do
    haml :changes, locals: {
      edited_files: parse_diffs(try_p4diff)
    }
  end

  post '/commit' do
    cmd = "git commit -am '" + params[:message] + "' | aha --no-header"
    content_type 'text/html', :charset => 'utf-8'
    %x[#{cmd}]
  end

  get '/diffs/*' do
    resource_short = params[:splat][0]
    resource = path_to resource_short
    haml :diffs, locals: {
      filename: resource_short,
      diffs: diffs_for(resource),
    }
  end

  get '/error' do
    haml :error, locals: {
        message: flash[:error]
    }
  end

  get '/login' do
    haml :login
  end

  post '/login' do
    message, code = p4sync params[:username], params[:password]
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

  get '/logout' do
    session.clear
    redirect '/'
  end

  post '/push' do
    content_type 'text/html', :charset => 'utf-8'
    %x[git push | aha --no-header]
  end

  post '/sync' do
    message, code = p4sync
    haml :sync, locals: {
      message: message,
      code: code
    }
  end

  get '/*' do
    resource = path_to params[:splat][0]
    extension = extension_of resource
    if extension == 'json'
      content_type 'application/json'
    elsif extension == 'html'
      content_type 'text/html', :charset => 'utf-8'
    end
    File.open(resource, 'r') do |file|
      file.read
    end
  end

  post '/*' do
    resource = path_to params[:splat][0]
    if (extension_of resource) != 'json'
      raise 'Only JSON files may be edited'
    end
    if File.exists? resource
      try_p4edit resource
    else
      FileUtils.mkdir_p File.dirname resource
      FileUtils.touch resource
      try_p4add resource
    end
    File.open(resource, 'w+') do |file|
      file.write(request.body.read)
    end
    %x[jshon -ISF #{resource}]
  end

  def client_name(username = nil)
    username ||= session[:username]
    username + 'Client'
  end

  def diffs_for(resource)
    diffs = parse_diffs try_p4diff resource
    if diffs.length and diffs[0]
      diffs[0][:diffs]
    else
      ''
    end
  end

  def ensure_escaped(resource)
    if resource.include? "'" and resource.include? '"'
      raise 'Resource contains invalid characters'
    elsif resource.include? "'"
      "\"#{resource}\""
    elsif resource.include? '"'
      "'#{resource}'"
    elsif resource.include? ' '
      "'#{resource}'"
    elsif /\s/.match resource
      raise 'Resource contains invalid characters'
    else
      resource
    end
  end

  def ensure_words(word, name)
    if /[^\w+\-\.]/.match(word)
      raise "Illegal characters in '#{name}'"
    end
  end

  def extension_of(resource)
    resource.split('.').pop
  end

  def p4(username = nil, password = nil)
    username ||= session[:username]
    password ||= session[:password]
    ensure_words username, 'username'
    ensure_words password, 'password'
    "p4 -u #{username} -P #{password} -c #{client_name username}"
  end

  def p4add(resource, username = nil, password = nil)
    [%x[#{p4 username, password} add #{ensure_escaped resource} 2>&1], $?]
  end

  def p4diff(file = nil, username = nil, password = nil)
    [%x[#{p4 username, password} diff #{ensure_escaped(file || '')}], $?]
  end

  def p4edit(resource, username = nil, password = nil)
    [%x[#{p4 username, password} edit #{ensure_escaped resource} 2>&1], $?]
  end

  def p4sync(username = nil, password = nil)
    [%x[#{p4 username, password} sync 2>&1], $?]
  end

  def parse_diffs(diffs)
    files = []
    diffs.lines.each do |line|
      if matches = /^==== .+#{Regexp.escape working_copy}\/(.+) ====$/.match(line)
        files.push({
          filename: matches[1],
          diffs: '',
        })
      else
        files[-1][:diffs] += line
      end
    end
    files
  end

  def path_to(resource, username = nil)
    File.join working_copy(username), resource
  end

  def try_p4add(resource, username = nil, password = nil)
    message, code = p4add resource, username, password
    if code != 0
      flash[:error] = message
      redirect '/error'
    end
  end

  def try_p4diff(file = nil, username = nil, password = nil)
    message, code = p4diff file, username, password
    if code != 0
      flash[:error] = message
      redirect '/error'
    end
    message
  end

  def try_p4edit(resource, username = nil, password = nil)
    message, code = p4edit resource, username, password
    if code != 0
      flash[:error] = message
      redirect '/error'
    end
  end

  def try_p4sync(username = nil, password = nil)
    message, code = p4sync username, password
    if code != 0
      flash[:error] = message
      redirect '/error'
    end
  end

  def working_copy(username = nil)
    username ||= session[:username]
    File.join File.dirname(__FILE__), 'wc', username
  end
end


