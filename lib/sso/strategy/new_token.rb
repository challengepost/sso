class SSO::Strategy::NewToken < SSO::Strategy::Base
  def self.should_process?(request)
    true # when all else fails
  end

  def token
    new_token
  end

  def call(env)
    request.session[:originator_key] = new_token.originator_key
    redirect_to sso_auth_url(new_token.key)
  end

  private

  def new_token
    @new_token ||= SSO::Token.create(request)
  end
end
