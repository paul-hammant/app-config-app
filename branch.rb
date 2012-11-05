def prompt(message, default = nil)
  $stdout.write message
  $stdout.write ' [' + default + ']' if default
  $stdout.write ': '
  input = $stdin.readline.strip
  input.length > 0 ? input : default
end

user = prompt 'user'
password = prompt 'password'
branch_name = prompt 'branch name'
source_branch = prompt 'source branch'

form  = "Branch: #{branch_name}" + '\n\n'
form += "Owner: #{user}" + '\n\n'
form += "Options: unlocked" + '\n\n'
form += "View:" + '\n\n'
form += '\t' + "//depot/app-config-app/#{source_branch}... //depot/app-config-app/#{branch_name}..." + '\n\n'

puts "Creating branch #{branch_name}..."
puts %x[echo "#{form}" | p4 -u #{user} -P #{password} -c #{user}Client branch -i]
puts %x[p4 -u #{user} -P #{password} -c #{user}Client integrate -b #{branch_name}]
puts %x[p4 -u #{user} -P #{password} -c #{user}Client submit -d "Created branch #{branch_name} from #{source_branch}"]
