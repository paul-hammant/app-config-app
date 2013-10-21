require_relative 'properties_file'

class SvnCredentialsFile < PropertiesFile
  def set_credentials(user, password)
    @properties['users'] ||= {}
    @properties['users'][user] = password
  end
end
