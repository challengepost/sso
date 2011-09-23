class SSO::Configuration
  include ActiveSupport::Configurable

  config_accessor :central_domain, :skip_paths, :redis

  def check_configuration!
    raise "You must specify SSO.config.redis"          if SSO.config.redis.nil?
    raise "You must specify SSO.config.central_domain" if SSO.config.central_domain.nil?
  end

  def skip_paths
    config.skip_paths || []
  end
end
