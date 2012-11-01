def prompt(message)
  $stdout.write message + ' '
  $stdin.readline
end

arg = 0
host = (ENV['P4PORT'] || ARGV[arg += 1] || (prompt 'perforce host/port:')).strip
user = (ARGV[arg += 1] || (prompt 'username:')).strip
email = (ARGV[arg += 1] || (prompt 'email:')).strip
password = (ARGV[arg += 1] || (prompt 'password:')).strip

form  = "User:   #{user}" + '\n\n'
form += "Email:  #{email}" + '\n\n'
form += "Password: #{password}" + '\n\n'
form += "FullName: #{user}" + '\n\n'

puts %x[echo "#{form}" | p4 -p #{host} user -i -f]

working_copy = File.join File.dirname(__FILE__), 'wc', user
client_name = user + 'Client'

form  = "Client: #{client_name}" + '\n\n'
form += "Owner:  #{user}" + '\n\n'
form += "Description:" + '\n'
form += '\t' + "Created by #{user}" + '\n\n'
form += "Root: #{working_copy}" + '\n\n'
form += "Options: noallwrite noclobber nocompress unlocked nomodtime normdir" + '\n\n'
form += "SubmitOptions: submitunchanged" + '\n\n'
form += "LineEnd: local" + '\n\n'
form += "View:" + '\n\n'
form += '\t' + "//depot/... //testClient/..." + '\n\n'

puts %x[echo "#{form}" | p4 -p #{host} -u #{user} -P #{password} client -i]
