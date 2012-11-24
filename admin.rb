def add_user(p4port = nil, user = nil, email = nil, password = nil)
  p4port ||= prompt 'p4port', ENV['P4PORT']
  user ||= prompt 'username'
  email ||= prompt 'email'
  password ||= prompt 'password'

  form  = "User: #{user}" + '\n\n'
  form += "Email: #{email}" + '\n\n'
  form += "Password: #{password}" + '\n\n'
  form += "FullName: #{user}" + '\n\n'

  puts "Creating user: #{user}"
  puts %x[echo "#{form}" | p4 -p #{p4port} user -i -f]

  form  = "Client: #{client_name user}" + '\n\n'
  form += "Owner: #{user}" + '\n\n'
  form += "Description:" + '\n'
  form += '\t' + "Created by #{user}" + '\n\n'
  form += "Root: #{working_copy user}" + '\n\n'
  form += "Options: noallwrite noclobber nocompress unlocked nomodtime normdir" + '\n\n'
  form += "SubmitOptions: submitunchanged" + '\n\n'
  form += "LineEnd: local" + '\n\n'
  form += "View:" + '\n\n'
  form += '\t' + "//depot/app-config-app/... //#{client_name user}/..." + '\n\n'

  puts "Creating client: #{client_name user}"
  puts %x[echo "#{form}" | p4 -p #{p4port} -u #{user} -P #{password} client -i]

  if !Dir.exists? working_copy user
    puts "Creating folder for working copy: #{working_copy user}"
    puts %x[mkdir -p #{working_copy user}]
  end

  puts "Synchronizing working copy..."
  puts %x[p4 -p #{p4port} -u #{user} -P #{password} -c #{client_name user} sync]
end

def branch(p4port = nil, user = nil, password = nil, new_branch = nil, source_branch = nil)
  p4port ||= prompt 'p4port', ENV['P4PORT']
  user ||= prompt 'username'
  password ||= prompt 'password'
  new_branch ||= prompt 'branch'
  source_branch ||= prompt 'source branch'

  form  = "Branch: #{source_branch}-#{new_branch}" + '\n\n'
  form += "Owner: #{user}" + '\n\n'
  form += "Options: unlocked" + '\n\n'
  form += "View:" + '\n\n'
  form += '\t' + "//depot/app-config-app/#{source_branch}... //depot/app-config-app/#{new_branch}..." + '\n\n'

  puts "Creating branch #{source_branch}-#{new_branch}..."
  puts %x[echo "#{form}" | p4 -p #{p4port} -u #{user} -P #{password} -c #{user}Client branch -i]
  puts %x[p4 -p #{p4port} -u #{user} -P #{password} -c #{user}Client integrate -b #{source_branch}-#{new_branch}]
  puts %x[p4 -p #{p4port} -u #{user} -P #{password} -c #{user}Client submit -d "(admin.rb) Created branch #{new_branch} from #{source_branch}"]
end

def client_name(user)
  "#{user}Client"
end

def prompt(message, default = nil)
  $stdout.write message
  $stdout.write ' [' + default + ']' if default
  $stdout.write ': '
  input = $stdin.readline.strip
  input.length > 0 ? input : default
end

def working_copy(user)
  File.join (File.expand_path File.dirname __FILE__), 'wc', user
end
