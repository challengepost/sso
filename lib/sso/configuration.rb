class SSO::Configuration
  include ActiveSupport::Configurable

  config_accessor :central_domain, :skip_paths

  def skip_paths
    config.skip_paths || []
  end
end
