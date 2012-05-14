class SSO::Configuration
  include ActiveSupport::Configurable

  config_accessor :central_domain, :skip_paths, :robots, :redis

  # checks the user agent against a list of bots
  # http://gurge.com/blog/2007/01/08/turn-off-rails-sessions-for-robots/
  # From Baidu to ZyBord: search engines
  # From UnwindFetchor to Twitmunin: twitter bots and twitter related hits
  DEFAULT_ROBOTS = /\b(Baidu|Gigabot|Googlebot|libwww-perl|lwp-trivial|msnbot|SiteUptime|Slurp|WordPress|ZIBB|ZyBorg|UnwindFetchor|TweetmemeBot|Voyager|yahoo\.com|Birubot|MetaURI|Twitterbot|PycURL|PostRank|Twitmunin)\b/i

  def check_configuration!
    raise "You must specify SSO.config.redis"          if SSO.config.redis.nil?
    raise "You must specify SSO.config.central_domain" if SSO.config.central_domain.nil?
  end

  def skip_paths
    config.skip_paths || []
  end

  def robots
    config.robots || DEFAULT_ROBOTS
  end

end
