class SSO::Strategy::ExistingTokenViaParam < SSO::Strategy::Base
  def self.should_process?(request)
    !!request['sso']  
  end

  def call
    if token = SSO::Token.find(@request.params['sso'])
      if @request.session[:originator_key]
        if @request.session[:originator_key] == token.originator_key
          ActiveRecord::Base.logger.info "Setting session token: #{token.key}"
          @request.session[:sso_token] = token.key
          redirect_to "http://#{token.request_domain}#{token.request_path}"
        else
          ActiveRecord::Base.logger.warn "Originator key didn't match while verifying token: #{token.key}"
          @app.call(@env)
        end
      else
        ActiveRecord::Base.logger.warn "No session originator key found while verifying token: #{token.key}"
        @app.call(@env)
      end
    else
      ActiveRecord::Base.logger.warn "Invalid token while attempting to verify: #{@request.params['sso']}"
      @app.call(@env)
    end
  end
end

