require_relative 'admin'

p4port = prompt 'p4port', ENV['P4PORT']
user = prompt 'user'

protect  = %x[p4 -p #{p4port} protect -o] + '\n'
protect += '\t' + "write user #{user} * //depot/app-config-app/..." + '\n\n'

puts %x[echo "#{protect}" | p4 -p #{p4port} protect -i]

useradd p4port, user
