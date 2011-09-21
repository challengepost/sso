class SSO::Configuration
  include ActiveSupport::Configurable

  config_accessor :skip_paths
end
