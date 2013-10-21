class SvnCredentialsFile
  attr :file, :properties

  def initialize(file)
    @file = file
    @credentials = {}
    IO.foreach(file) do |line|
      @credentials[$1.strip] = $2 if line =~ /([^=]*)=(.*)\/\/(.*)/ || line =~ /([^=]*)=(.*)/
    end
  end

  def to_s
     output = "File Name #{@file} \n"
     @credentials.each { |key, value| output += " #{key}= #{value} \n" }
     output
  end

  def set_credentials(user, password)
    @credentials[user] = password
  end

  def save
    File.open(@file,"w+") do |file|
      file.puts("[users]")
      @credentials.each { |key, value| file.puts "#{key} = #{value}\n" }
    end
  end
end
