def prompt(message, default = nil)
  $stdout.write message
  $stdout.write ' [' + default + ']' if default
  $stdout.write ': '
  input = $stdin.readline.strip
  input if input.length > 0 else default
end

p4port = prompt 'p4port', ENV['P4PORT']
user = prompt 'username'
email = prompt 'email'
password = prompt 'password'

form  = "User: #{user}" + '\n\n'
form += "Email: #{email}" + '\n\n'
form += "Password: #{password}" + '\n\n'
form += "FullName: #{user}" + '\n\n'

puts "Creating user: #{user}"
puts %x[echo "#{form}" | p4 -p #{p4port} user -i -f]

working_copy = File.join File.expand_path(File.dirname(__FILE__)), 'wc', user
client_name = user + 'Client'

form  = "Client: #{client_name}" + '\n\n'
form += "Owner: #{user}" + '\n\n'
form += "Description:" + '\n'
form += '\t' + "Created by #{user}" + '\n\n'
form += "Root: #{working_copy}" + '\n\n'
form += "Options: noallwrite noclobber nocompress unlocked nomodtime normdir" + '\n\n'
form += "SubmitOptions: submitunchanged" + '\n\n'
form += "LineEnd: local" + '\n\n'
form += "View:" + '\n\n'
form += '\t' + "//depot/app-config-app/... //#{client_name}/..." + '\n\n'

puts "Creating client: #{client_name}"
puts %x[echo "#{form}" | p4 -p #{p4port} -u #{user} -P #{password} client -i]

if (!Dir.exists? working_copy)
  puts "Creating folder for working copy: #{working_copy}"
  puts %x[mkdir -p #{working_copy}]
end

puts "Synchronizing working copy..."
puts %x[p4 -p #{p4port} -u #{user} -P #{password} -c #{client_name} sync]

if (Dir.entries working_copy).length == 2
  puts "stack_configuration.json not under source control, adding it..."
  puts %x[mkdir -p #{(File.join working_copy, 'dev')}]
  puts %x[cp stack_configuration.json #{(File.join working_copy, 'dev/stack_configuration.json')}]
  puts %x[p4 -p #{p4port} -u #{user} -P #{password} -c #{client_name} add #{File.join working_copy, 'dev/stack_configuration.json'}]
  puts %x[p4 -p #{p4port} -u #{user} -P #{password} -c #{client_name} submit -d "Initial import of stack_configuration.json"]
end
