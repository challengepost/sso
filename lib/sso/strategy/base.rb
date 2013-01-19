class SSO::Strategy::Base

  attr_reader :app, :env, :request

  def initialize(app, env, request)
    @app, @env, @request = app, env, request
  end

  def redirect_to(url)
    response.redirect(url)
    response.finish
  end

  def response
    @response ||= Rack::Response.new
  end

  def self.should_process?(request)
    false
  end

  def call
    raise "Subclass should implement!"
  end

end

