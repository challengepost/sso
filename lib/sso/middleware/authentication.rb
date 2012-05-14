class SSO::Middleware::Authentication

  SSO_STRATEGIES = [
    SSO::Strategy::Skip,
    SSO::Strategy::ExistingTokenViaRedirect,
    SSO::Strategy::ExistingTokenViaParam,
    SSO::Strategy::ExistingTokenViaSession,
    SSO::Strategy::NewToken
  ]

  def initialize(app)
    @app = app
  end

  def call(env)
    SSO.config.check_configuration!
    SSO::Token.current_token = nil
    request = Rack::Request.new(env)
    initialize_sso_strategy(@app, env, request).call
  end

private
  
  def initialize_sso_strategy(app, env, request)
    choose_authentication_strategy_class(request).new(app, env, request)
  end

  def choose_authentication_strategy_class(request)
    SSO_STRATEGIES.detect { |strategy_class| strategy_class.should_process?(request) }
  end
  
end
