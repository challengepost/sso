require 'active_support'
require 'action_dispatch'

module SSO
  extend ActiveSupport::Autoload

  autoload :Middleware
  autoload :Token
  autoload :Configuration
  autoload :Strategy

  def self.config
    @configuration ||= Configuration.new
  end
end
