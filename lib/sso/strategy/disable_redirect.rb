class SSO::Strategy::DisableRedirect < SSO::Strategy::Base
  def self.should_process?(request)
    SSO.config.disable_redirect?
  end

  def call(env)
    store_current_sso_token current_sso_token, env
    app.call(env)
  end

  private

  def current_sso_token
    @current_sso_token ||= find_token || create_token
  end

  def find_token
    SSO::Token.find(request.session[:sso_token]) if request.session[:sso_token]
  end

  def create_token
    SSO::Token.create(request).tap do |token|
      request.session[:sso_token] = token.key
    end
  end

end
