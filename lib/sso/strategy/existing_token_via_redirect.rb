class SSO::Strategy::ExistingTokenViaRedirect < SSO::Strategy::Base
  def self.should_process?(request)
    sso_auth_url?(request.path)
  end

  # responds to /sso/auth/<key>
  def call(env)
    return invalid_request_token_call(env) if request_token.nil?
    logger :info, "Authenticating session for central domain: #{request.session[:sso_token]}"

    if session_token
      logger :info, "Existing token found: #{session_token.key}"
      swap_request_token_with_session_token!
      logger :info, "Existing token updated: #{session_token.inspect}"
    else
      logger :info, "Existing token not found."
    end

    request.session[:sso_token] = request_token.key
    redirect_to request_token_return_url
  end

  protected

  def request_token
    @request_token ||= SSO::Token.find(request.path.gsub("/sso/auth/", ""))
  end

  def session_token
    @session_token ||= SSO::Token.find(request.session[:sso_token])
  end

  def swap_request_token_with_session_token!
    session_token.update(request_token)
    @request_token.destroy
    @request_token = session_token
  end

  def request_token_return_url
    join = request_token.request_url.match(%r{\?}) ? "&" : "?"
    [request_token.request_url, "sso=#{request_token.key}"].join(join)
  end

  def invalid_request_token_call(env)
    logger :info, "Invalid token while authenticating"
    redirect_to request.referrer
  end
end
