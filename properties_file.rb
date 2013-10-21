class PropertiesFile
  attr :file, :properties

  def initialize(file)
    @file = file
    @properties = {}

    IO.foreach(file) do |line|
      next if line =~ /^#/ # Ignore Comments
      @current_section = $1 if line =~ /\[(.*?)\]/ # Set [content] as current section

      unless @current_section.nil?
        @properties[@current_section] ||= {}
        @properties[@current_section][$1.strip] = $2.strip if line =~ /([^=]*)=(.*)\/\/(.*)/ || line =~ /([^=]*)=(.*)/
      end
    end
  end

  def to_s
     output = ""
     @properties.each do |section, properties|
       output += "[#{section}]\n"
       properties.each do |key, value|
         output += "#{key} = #{value}\n"
       end
     end
     output
  end

  def save
    File.open(@file,"w+") do |file|
      file.puts self.to_s
    end
  end
end
