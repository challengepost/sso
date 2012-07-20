class SSO::Strategy::ExistingTokenViaParam < SSO::Strategy::Base
  def self.should_process?(request)
    !!request['sso']  
  end

  def call
    return invalid_token_call if token.nil?
    return missing_originator_key_in_session_call if originator_key_in_session.nil?
    return invalid_originator_key_call unless originator_key_verified?

    ActiveRecord::Base.logger.info "Setting session token: #{token.key}"
    @request.session[:sso_token] = token.key
    redirect_to "http://#{token.request_domain}#{token.request_path}"
  end

  protected

  def originator_key_verified?
    originator_key_in_session == token.originator_key
  end

  def token
    @token ||= SSO::Token.find(@request.params['sso'])
  end

  def originator_key_in_session
    @request.session[:originator_key]
  end

  def invalid_token_call
    ActiveRecord::Base.logger.warn "Invalid token while attempting to verify: #{@request.params['sso']}"
    @app.call(@env)
  end

  def missing_originator_key_in_session_call
    ActiveRecord::Base.logger.warn "No session originator key found while verifying token: #{token.key}"
    @app.call(@env)
  end

  def invalid_originator_key_call
    ActiveRecord::Base.logger.warn "Originator key didn't match while verifying token: #{token.key}"
    @app.call(@env)
  end
end
