class SSO::Strategy::ExistingTokenViaSession < SSO::Strategy::Base
  def self.should_process?(request)
    SSO::Token.find(request.session[:sso_token]).tap do |current_sso_token|
      request['current_sso_token'] = current_sso_token if current_sso_token
    end
  end

  def token
    current_sso_token
  end

  def call(env)
    # TODO
    # Deprecate SSO::Token.current_token
    SSO::Token.current_token = current_sso_token
    env['current_sso_token'] = current_sso_token
    ActiveRecord::Base.logger.info "Request for token: #{current_sso_token.key}"
    app.call(env)
  end

  private

  def current_sso_token
    request['current_sso_token']
  end
end
