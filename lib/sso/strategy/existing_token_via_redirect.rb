class SSO::Strategy::ExistingTokenViaRedirect < SSO::Strategy::Base
  def self.should_process?(request)
    request.path =~ /^\/sso\/auth/  
  end

  def call
    return invalid_request_token_call if request_token.nil?
    ActiveRecord::Base.logger.info "Authenticating session for central domain: #{@request.session[:sso_token]}"

    if session_token
      ActiveRecord::Base.logger.info "Existing token found: #{session_token.key}"
      update_tokens!
      ActiveRecord::Base.logger.info "Existing token updated: #{session_token.inspect}"
    else
      ActiveRecord::Base.logger.info "Existing token not found."
    end

    @request.session[:sso_token] = request_token.key
    redirect_to request_token_return_url
  end

  protected

  def request_token
    @request_token ||= SSO::Token.find(@request.path.gsub("/sso/auth/", ""))
  end

  def session_token
    @session_token ||= SSO::Token.find(@request.session[:sso_token])
  end

  def update_tokens!
    session_token.update(request_token)
    update_request_token!
  end

  def update_request_token!
    request_token.destroy
    @request_token = session_token
  end

  def request_token_return_url
    "http://#{request_token.request_domain}#{request_token.request_path}#{request_token.request_path.match(/\?/) ? "&sso=" : "?sso="}#{request_token.key}"
  end

  def invalid_request_token_call
    ActiveRecord::Base.logger.info "Invalid token while authenticating"
    redirect_to @request.referrer
  end
end