module AppCfg
  module Helpers
    def working_copy(user)
      File.join(File.dirname(__FILE__), 'wc', user)
    end

    def are_valid_scm_credentials?(user, password)
      scm_sync(user, password)
    end

    def directory_hash(path, name=nil)
      name ||= path
      entry = {
        path: path,
        name: name,
        directory?: File.directory?(path)
      }

      if File.directory?(path)
        entry[:children] = []
        Dir.foreach(path) do |child|
          next if %w[. .. .svn].include?(child)
          entry[:children] << directory_hash(File.join(path, child), child)
        end
      end
      entry
    end

    def path_to(resource)
      File.join(working_copy(session[:user]), resource)
    end

    def tree_list(entry)
      output = ''
      if entry[:directory?]
        output += '<li>' + entry[:name] + "\n"
        output += '<ul>' + "\n"
        entry[:children].each { |child| output += tree_list(child) }
        output += '</ul>' + "\n"
        output += '</li>' + "\n"
      elsif entry[:name].include? '.html'
        output += '<li>'
        output += '<a href="' + entry[:path].sub(/^#{Regexp.escape(working_copy(session[:user]))}\//, '') + '">'
        output += entry[:name].sub(/html$/, 'json') + '</a>'
        output += '</li>' + "\n"
      end
      output
    end

    def svn(command, user, password)
      command_output = `svn #{command} svn://localhost \
         --non-interactive --no-auth-cache \
         --username #{user} --password #{password} \
         2>&1 #{working_copy(user)}`

      { command_output: command_output,
        exit_code: $? }
    end

    def scm_sync(user, password)
      svn('checkout', user, password)[:exit_code] == 0
    end

    def sync
      return false unless session[:user]

      time = Time.now.to_i

      if session[:last_sync].nil? or session[:last_sync] < Time.now.to_i - 30
        scm_sync(session[:user], session[:password])
        session[:last_sync] = time
        request.logger.debug 'Performed Sync'
      end
    end
  end
end
