# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

require 'rack/test'

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include AppHelper

  config.before(:each) do
    SSO.config.central_domain = "centraldomain.com"
    SSO.config.redis = $redis
  end
end
