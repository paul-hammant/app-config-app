require_relative 'properties_file'

class SvnPermissionsFile < PropertiesFile
  def initialize(file, options = {})
    super(file)
    @environments = options[:environments]
    @environments.each do |env|
      @properties[env] ||= {}
    end
    super_user = options[:super_user]
    @properties['/'] = {}
    @properties['/'][super_user] = 'rw'
    @properties['/']['*'] = 'r'
  end

  def set_permissions(env, user, perms)
    raise 'Invalid Environment' unless @environments.include?(env)
    @environments.each do |env, properties|
      @properties[env][user] ||= ''
    end
    @properties[env][user] = perms
  end
end
