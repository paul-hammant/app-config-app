require 'highline/import'

require_relative 'admin'

p4port = prompt 'p4port', (ENV['P4PORT'] || 'localhost:1666')
user = prompt 'user'
email = prompt 'email'
password = ask('password: ') {|q| q.echo = "*"}

protect  = %x[p4 -p #{p4port} protect -o].gsub(/^.+write user \* \* \/\/\.\.\./, '') + '\n'
protect += '\t' + "write user #{user} * //depot/app-config-app/..." + '\n\n'
protect += '\twrite user sally-runtime * //depot/app-config-app/prod/...\n\n'
protect += '\tread user sally-runtime * //depot/app-config-app/staging/...\n\n'
protect += '\tread user sally-runtime * //depot/app-config-app/dev/...\n\n'
protect += '\twrite user joe-developer * //depot/app-config-app/dev/...\n\n'
protect += '\twrite user jimmy-qa * //depot/app-config-app/staging/...\n\n'
protect += '\tread user jimmy-qa * //depot/app-config-app/dev/...\n\n'
protect += '\tread user dev-app * //depot/app-config-app/dev/...\n\n'
protect += '\tread user qa-app * //depot/app-config-app/staging/...\n\n'
protect += '\tread user prod-app * //depot/app-config-app/prod/...\n\n'

puts %x[echo "#{protect}" | p4 -p #{p4port} protect -i]

add_user p4port, user, email, password

if (Dir.entries working_copy user).sort! == ['.', '..']
  puts "**_configuration files not under source control, adding them..."
  puts %x[mkdir -p #{(File.join (working_copy user), 'dev')}]
  puts %x[cp aardvark_configuration.json #{(File.join (working_copy user), 'dev/aardvark_configuration.json')}]
  puts %x[cp aardvark_configuration.html #{(File.join (working_copy user), 'dev/aardvark_configuration.html')}]
  puts %x[cp banana_configuration.json #{(File.join (working_copy user), 'dev/banana_configuration.json')}]
  puts %x[cp banana_configuration.html #{(File.join (working_copy user), 'dev/banana_configuration.html')}]
  puts %x[p4 -p #{p4port} -u #{user} -P #{password} -c #{client_name user} add #{File.join (working_copy user), 'dev/aardvark_configuration.json'}]
  puts %x[p4 -p #{p4port} -u #{user} -P #{password} -c #{client_name user} add #{File.join (working_copy user), 'dev/aardvark_configuration.html'}]
  puts %x[p4 -p #{p4port} -u #{user} -P #{password} -c #{client_name user} add #{File.join (working_copy user), 'dev/banana_configuration.json'}]
  puts %x[p4 -p #{p4port} -u #{user} -P #{password} -c #{client_name user} add #{File.join (working_copy user), 'dev/banana_configuration.html'}]
  puts %x[p4 -p #{p4port} -u #{user} -P #{password} -c #{client_name user} submit -d "Initial import of **_configuration.json/html"]
end

branch p4port, user, password, 'staging', 'dev'
branch p4port, user, password, 'prod', 'staging'

add_user p4port, 'sally-runtime', 'sally@test.com', 'bananas'
add_user p4port, 'joe-developer', 'joe@test.com', 'oranges'
add_user p4port, 'jimmy-qa', 'jimmy@test.com', 'apples'
add_user p4port, 'dev-app', 'admin@test.com', 's3cret1'
add_user p4port, 'qa-app', 'admin@test.com', 's3cret2'
add_user p4port, 'prod-app', 'admin@test.com', 's3cret3'
