class SSO::Strategy::Base

  attr_reader :app, :request

  def self.sso_auth_url?(path)
    path =~ /^\/sso\/auth/
  end

  def self.sso_identity_url?(path)
    path =~ /^\/sso\/identity/
  end

  def self.should_process?(request)
    false
  end

  def initialize(app, request)
    @app, @request = app, request
  end

  def redirect_to(url)
    response.redirect(url)
    response.finish
  end

  def response
    @response ||= Rack::Response.new
  end

  def sso_auth_url(token_key)
    "#{sso_host}/sso/auth/#{token_key}"
  end

  def sso_host
    "#{SSO.config.central_scheme}://#{SSO.config.central_domain}"
  end

  def sso_auth_request?
    self.class.sso_auth_url?(request.path)
  end

  def sso_identity_request?
    self.class.sso_identity_url?(request.path)
  end

  def call(env)
    raise "Subclass should implement!"
  end

  def announce
    logger :info, "Using #{self.class.name} for #{request.host}"
  end

  def logger(method, message)
    ActiveRecord::Base.logger.send(method, "SSO: #{message}")
  end

end

