class SSO::Strategy::ExistingTokenViaSession < SSO::Strategy::Base
  def self.should_process?(request)
    SSO::Token.find(request.session[:sso_token]).tap do |current_sso_token|
      request['current_sso_token'] = current_sso_token if current_sso_token
    end || passthrough_request?(request)
  end

  def self.passthrough_request?(request)
    SSO.config.passthroughs.any? { |passthrough| passthrough.call(request) }
  end

  def token
    current_sso_token
  end

  def call(env)
    # TODO
    # Deprecate SSO::Token.current_token
    SSO::Token.current_token = current_sso_token
    env['current_sso_token'] = current_sso_token

    SSO::Token.run_callbacks(current_sso_token)

    logger :info, "Request for token: #{current_sso_token.try(:key)}"
    app.call(env)
  end

  private

  def current_sso_token
    request['current_sso_token']
  end
end
