module AppCfg
  module Helpers
    def ensure_words(word, name)
      if /[^\w+\-\.]/.match word
        raise "Illegal characters in '#{name}'"
      end
    end

    def directory_hash(path, name=nil)
      name ||= path
      entry = {
          path: path,
          name: name,
          directory?: (File.directory? path)
      }
      if File.directory? path
        entry[:children] = []
        Dir.foreach path do |child|
          next if %w[. .. .svn].include? child
          entry[:children] << (directory_hash (File.join path, child), child)
        end
      end
      entry
    end

    def working_copy(username = session[:username])
      File.join(File.dirname(__FILE__), 'wc', username)
    end

    def p4sync(username = nil, password = nil)
      username ||= session[:username]
      password ||= session[:password]

      credentials = "--username #{username} --password #{password}"
      [%x[svn checkout svn://localhost #{credentials} --non-interactive --no-auth-cache 2>&1 #{working_copy(username)}], $?]
    end
  end
end
