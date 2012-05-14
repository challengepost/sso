class SSO::Strategy::ExistingTokenViaSession < SSO::Strategy::Base
  def self.should_process?(request)
    SSO::Token.find(request.session[:sso_token]).tap do |current_sso_token|
      request['current_sso_token'] = current_sso_token if current_sso_token
    end
  end

  def call
    # TODO
    # Remove use of SSO::Token.current_token
    # in favor of adding current_sso_token to @env
    # example in warden: https://github.com/hassox/warden/blob/master/lib/warden/manager.rb#L33
    SSO::Token.current_token = current_sso_token
    ActiveRecord::Base.logger.info "Request for token: #{current_sso_token.key}"
    @app.call(@env)
  end

  def current_sso_token
    @request['current_sso_token']
  end
end
