class SSO::Configuration
  include ActiveSupport::Configurable

  config_accessor :central_domain, :skip_paths
end
