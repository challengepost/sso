class SSO::Strategy::NewToken < SSO::Strategy::Base
  def self.should_process?(request)
    true # when all else fails
  end

  def token
    new_token
  end

  def call(env)
    ActiveRecord::Base.logger.info self.class.name
    request.session[:originator_key] = new_token.originator_key
    redirect_to "http://#{SSO.config.central_domain}/sso/auth/#{new_token.key}"
  end

  private

  def new_token
    @new_token ||= SSO::Token.create(request)
  end
end
