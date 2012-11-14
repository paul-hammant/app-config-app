require 'highline/import'

require_relative 'admin'

p4port = prompt 'p4port', ENV['P4PORT']
user = prompt 'user'
email = prompt 'email'
password = ask('password: ') {|q| q.echo = "*"} 

protect  = %x[p4 -p #{p4port} protect -o].gsub(/^.+write user \* \* \/\/\.\.\./, '') + '\n'
protect += '\t' + "write user #{user} * //depot/app-config-app/..." + '\n\n'
protect += '\twrite user sally-runtime * //depot/app-config-app/prod/...\n\n'
protect += '\tread user sally-runtime * //depot/app-config-app/stage/...\n\n'
protect += '\tread user sally-runtime * //depot/app-config-app/dev/...\n\n'
protect += '\twrite user joe-developer * //depot/app-config-app/dev/...\n\n'
protect += '\twrite user jimmy-qa * //depot/app-config-app/stage/...\n\n'
protect += '\tread user jimmy-qa * //depot/app-config-app/dev/...\n\n'
protect += '\tread user dev-app * //depot/app-config-app/dev/...\n\n'
protect += '\tread user qa-app * //depot/app-config-app/stage/...\n\n'
protect += '\tread user prod-app * //depot/app-config-app/prod/...\n\n'

puts %x[echo "#{protect}" | p4 -p #{p4port} protect -i]

useradd p4port, user, email, password

branch p4port, user, password, 'stage', 'dev'
branch p4port, user, password, 'prod', 'stage'

useradd p4port, 'sally-runtime', 'sally@test.com', 'bananas'
useradd p4port, 'joe-developer', 'joe@test.com', 'oranges'
useradd p4port, 'jimmy-qa', 'jimmy@test.com', 'apples'
useradd p4port, 'dev-app', 'admin@test.com', 's3cret1'
useradd p4port, 'qa-app', 'admin@test.com', 's3cret2'
useradd p4port, 'prod-app', 'admin@test.com', 's3cret3'

File.open 'passwords.yaml', 'w' do |file|
  file.write "dev-app: s3cret1\n"
  file.write "qa-app: s3cret2\n"
  file.write "prod-app: s3cret3\n"
end
