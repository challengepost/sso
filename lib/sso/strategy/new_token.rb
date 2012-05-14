class SSO::Strategy::NewToken < SSO::Strategy::Base
  def self.should_process?(request)
    true # when all else fails
  end

  def call
    @request.session[:originator_key] = new_token.originator_key
    redirect_to "http://#{SSO.config.central_domain}/sso/auth/#{new_token.key}"
  end

  def new_token
    @new_token ||= SSO::Token.create(@request)
  end
end