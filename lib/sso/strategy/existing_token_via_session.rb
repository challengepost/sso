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
    set_current_sso_token current_sso_token, env
    app.call(env)
  end

  private

  def current_sso_token
    request['current_sso_token']
  end
end
