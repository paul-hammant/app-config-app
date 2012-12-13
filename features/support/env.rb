# If you want to use a different mock framework than
# RSpec-Mocks - just set configure that accordingly
#
# require 'rspec/core'
# RSpec.configure do |c|
#  c.mock_framework = :rspec
#  c.mock_framework = :mocha
#  c.mock_framework = :rr
#  c.mock_framework = :flexmock
# end

ENV['RACK_ENV'] = 'test'

require 'capybara'
require 'capybara/cucumber'
require 'cucumber/rspec/doubles'
require 'rack/test'
require 'rspec/expectations'

class SinatraWorld
  require 'selenium-webdriver'
  Capybara.default_driver = :selenium

# use the rackup file to load the apps w/their respective URL mappings, sweet!
  Capybara.app = eval "Rack::Builder.new {( " + File.read(File.dirname(__FILE__) + '/../../config.ru') + "\n )}"

  include Capybara::DSL
  include RSpec::Expectations
end

World do
  SinatraWorld.new
end
