require 'highline/import'

require_relative 'svn_credentials_file'
require_relative 'svn_permissions_file'

CURRENT_DIRECTORY = File.expand_path(File.dirname(__FILE__))
OUTPUT_CMD = true

def working_copy(user)
  working_copy_dir = File.join(
    CURRENT_DIRECTORY,
    'wc',
    user
  )

  unless Dir.exists?(working_copy_dir)
    puts "Creating folder for working copy: #{working_copy_dir}"
    puts %x[mkdir -p #{working_copy_dir}]
  end

  working_copy_dir
end

def is_empty?(directory)
  Dir.entries(directory).sort! == %w[. ..]
end

def execute(command)
  puts command if OUTPUT_CMD
  puts %x[#{command}]
end

def add_user(user, password)
  svn_credentials_file = SvnCredentialsFile.new(
    File.join(CURRENT_DIRECTORY, 'svn_files/conf/passwd')
  )

  svn_credentials_file.set_credentials(user, password)
  svn_credentials_file.save
end

def set_permissions(env, user, perm)
  svn_permissions_file = SvnPermissionsFile.new(
    File.join(CURRENT_DIRECTORY, 'svn_files/conf/authz'),
    environments: ['/dev', '/qa', '/staging', '/prod'],
    super_user: 'jeffersongirao'
  )
  svn_permissions_file.set_permissions(env, user, perm)
  svn_permissions_file.save
end

def map_changes(env, new_env, user, password)
  credentials = "--username #{user} --password #{password}"
  execute("svn copy svn://localhost/#{env} svn://localhost/#{new_env} -m 'Created config mapping from #{env} to #{new_env}' #{credentials}")
end

user = ask('user:')
password = ask('password:') { |q| q.echo = '*' }

add_user(user, password)
set_permissions('/dev', user, 'rw')
set_permissions('/qa',  user, 'rw')
set_permissions('/staging', user, 'rw')
set_permissions('/prod', user, 'rw')

user_working_copy = working_copy(user)
if is_empty?(user_working_copy)
  puts "**_configuration files not under source control, adding them..."

  credentials = "--username #{user} --password #{password}"

  execute("svn import #{File.join(CURRENT_DIRECTORY, 'example_config')} svn://localhost/dev -m 'Initial import of **_configuration.json/html/js (examples)' #{credentials}")
end

map_changes('dev', 'qa', user, password)
map_changes('qa', 'staging', user, password)
map_changes('staging', 'prod', user, password)

add_user('sally-runtime', 'bananas')
set_permissions('/staging', 'sally-runtime', 'r')
set_permissions('/prod', 'sally-runtime', 'rw')

add_user('joe-developer', 'oranges')
set_permissions('/dev', 'joe-developer', 'rw')

add_user('jimmy-qa', 'apples')
set_permissions('/dev', 'jimmy-qa', 'r')
set_permissions('/qa', 'jimmy-qa', 'rw')
set_permissions('/staging', 'jimmy-qa', 'rw')

add_user('dev-app', 's3cret1')
set_permissions('/dev', 'dev-app', 'r')

add_user('qa-app', 's3cret2')
set_permissions('/dev', 'qa-app', 'r')
set_permissions('/staging', 'qa-app', 'r')

add_user('prod-app', 's3cret3')
set_permissions('/prod', 'prod-app', 'r')
