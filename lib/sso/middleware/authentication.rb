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
    strategy_class = choose_authentication_strategy_class(request)
    strategy_class.new(@app, env, request).call
  end

private

  def choose_authentication_strategy_class(request)
    SSO_STRATEGIES.detect { |strategy_class| strategy_class.should_process?(request) }
  end
  
end
