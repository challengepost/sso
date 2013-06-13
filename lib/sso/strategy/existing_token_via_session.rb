class SSO::Strategy::ExistingTokenViaSession < SSO::Strategy::Base
  def self.should_process?(request)
    SSO::Token.find(request.session[:sso_token]).tap do |current_sso_token|
      request['current_sso_token'] = current_sso_token if current_sso_token
    end || passthrough_request?(request)
  end

  def self.passthrough_request?(request)
    SSO.config.passthroughs.any? { |passthrough|
      passthrough.call(request)
    }
  end

  def token
    current_sso_token
  end

  # responds to /sso/identity
  # calls app for all other urls
  def call(env)
    # TODO
    # Deprecate SSO::Token.current_token
    SSO::Token.current_token = current_sso_token
    env['current_sso_token'] = current_sso_token

    SSO::Token.run_callbacks(current_sso_token)

    if sso_identity_request?
      logger :info, "Identity request: #{current_sso_token.try(:key)}"
      respond_with_sso_identity
    else
      logger :info, "Request for token: #{current_sso_token.try(:key)}"
      app.call(env)
    end
  end

  private

  def current_sso_token
    request['current_sso_token']
  end

  def user_signed_in?
    !!current_sso_token.identity
  end

  def respond_with_sso_identity
    status = user_signed_in? ? 200 : 401
    [
      status,
      {'Content-Type' => 'text/html'},
      [render_identity_html]
    ]
  end

  def render_identity_html
    require 'erb'
    ERB.new(File.read(identity_template)).result(binding)
  end

  def identity_template
    File.expand_path("../../views/identity.html.erb", __FILE__)
  end
end
