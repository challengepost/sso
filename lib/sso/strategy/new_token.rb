class SSO::Strategy::NewToken < SSO::Strategy::Base
  def self.should_process?(request)
    true # when all else fails
  end

  def token
    new_token
  end

  def call(env)
    request.session[:originator_key] = new_token.originator_key
    redirect_to "#{central_domain_scheme}://#{SSO.config.central_domain}/sso/auth/#{new_token.key}"
  end

  private

  def new_token
    @new_token ||= SSO::Token.create(request)
  end

  # This is a cheap hack to avoid problems with forcing
  # ssl by not specifying the correct scheme for the
  # central domain
  def central_domain_scheme
    return 'http' unless defined?(Settings)
    Settings.ssl.enabled? ? 'https' : 'http'
  end
end
