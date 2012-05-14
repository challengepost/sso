class SSO::Strategy::ExistingTokenViaRedirect < SSO::Strategy::Base
  def self.should_process?(request)
    request.path =~ /^\/sso\/auth/  
  end

  def call
    if token = SSO::Token.find(@request.path.gsub("/sso/auth/", ""))
      ActiveRecord::Base.logger.info "Authenticating session for central domain: #{@request.session[:sso_token]}"
      if existing_token = SSO::Token.find(@request.session[:sso_token])
        ActiveRecord::Base.logger.info "Existing token found: #{existing_token.key}"
        existing_token.update(token)
        token.destroy
        token = existing_token
        ActiveRecord::Base.logger.info "Existing token updated: #{existing_token.inspect}"
      else
        ActiveRecord::Base.logger.info "Existing token not found."
      end

      @request.session[:sso_token] = token.key
      redirect_to "http://#{token.request_domain}#{token.request_path}#{token.request_path.match(/\?/) ? "&sso=" : "?sso="}#{token.key}"
    else
      ActiveRecord::Base.logger.info "Invalid token while authenticating"
      redirect_to @request.referrer
    end
  end
end