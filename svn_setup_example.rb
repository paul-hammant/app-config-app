require 'highline/import'

require_relative 'svn_credentials_file'

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

def add_user_to_example_repo(user, password)
  svn_credentials_file = SvnCredentialsFile.new(
    File.join(CURRENT_DIRECTORY, 'svn_files/conf/passwd')
  )

  svn_credentials_file.set_credentials(user, password)
  svn_credentials_file.save
end

def map_changes(source_env, new_env, user, password)
  execute("svn copy svn://localhost/#{source_env} svn://localhost/#{new_env} -m 'Created change mapping from #{source_env} to #{new_env}'")
end

user = ask('user:')
password = ask('password:') { |q| q.echo = '*' }

add_user_to_example_repo(user, password)

user_working_copy = working_copy(user)
if is_empty?(user_working_copy)
  puts "**_configuration files not under source control, adding them..."

  dev_working_copy = File.join(user_working_copy, 'dev')

  execute("mkdir -p #{dev_working_copy}")
  execute("cp example_config/* #{dev_working_copy}")

  credentials = "--username #{user} --password #{password}"

  execute("svn import #{dev_working_copy} svn://localhost/dev -m 'Initial import of **_configuration.json/html/js (examples)' #{credentials}")
end

map_changes('dev', 'qa', user, password)
map_changes('qa', 'staging', user, password)
map_changes('staging', 'prod', user, password)
