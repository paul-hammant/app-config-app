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

require_relative '../../appcfg'
require 'cucumber/rspec/doubles'
require 'rack/test'
require 'capybara/cucumber'

Capybara.app = Rack::URLMap.new({
    '/' => AppCfg::App,
    '/error' => AppCfg::ErrorApp,
})
