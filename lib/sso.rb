require 'active_support'
require 'action_dispatch'

module SSO
  extend ActiveSupport::Autoload

  autoload :Callbacks
  autoload :Configuration
  autoload :Middleware
  autoload :Strategy
  autoload :TestHelpers
  autoload :Token

  def self.config
    @configuration ||= Configuration.new
  end

  # Public: Configure SSO via block syntax
  #
  # Examples
  #
  #  SSO.configure do |sso|
  #    # don't do any SSO processing on matching paths
  #    sso.skip_paths = [%r(^/skipme$)]
  #
  #    # perform SSO processing without redirects
  #    sso.passthrough_request do |req|
  #      req.host == "api.example.com"
  #    end
  #  end
  #
  def self.configure
    yield config if block_given?
  end

  # Provides helper methods to SSO for testing.
  #
  # To setup SSO in test mode call the SSO.test_mode! once before all tests are executed.
  #
  # @example
  #   SSO.test_mode!
  #
  # This will provide a number of methods.
  # SSO.on_next_request(&blk) - captures a block which is yielded the current sso token on the next request
  # SSO.test_reset! - removes any captured blocks that would have been executed on the next request
  #
  # SSO.test_reset! should be called in after blocks for rspec, or teardown methods for Test::Unit
  def self.test_mode!
    SSO.extend SSO::TestHelpers
    SSO::Token.on_request do |current_sso_token|
      while block = SSO.next_request_commands.shift
        block.call(current_sso_token)
      end
    end
  end

  def self.request_for_sso_auth_url?(request)
    request.path =~ /^\/sso\/auth/
  end

end
