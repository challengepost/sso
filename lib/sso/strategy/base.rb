class SSO::Strategy::Base

  attr_reader :app, :request

  def initialize(app, request)
    @app, @request = app, request
  end

  def redirect_to(url)
    response.redirect(url)
    response.finish
  end

  def response
    @response ||= Rack::Response.new
  end

  def self.should_process?(request)
    false
  end

  def call(env)
    raise "Subclass should implement!"
  end

  def announce
    logger :info, "Using #{self.class.name} for #{request.host}"
  end

  def logger(method, message)
    ActiveRecord::Base.logger.send(method, "SSO: #{message}")
  end

  def set_current_sso_token(token, env)
    SSO::Token.current_token = token
    env['current_sso_token'] = token

    SSO::Token.run_callbacks(token)

    logger :info, "Request for token: #{token.try(:key)}"
  end

end

