class SSO::Strategy::Base
  def initialize(app, env, request)
    @app, @env, @request = app, env, request
  end

  def redirect_to(url)
    response = Rack::Response.new
    response.redirect(url)
    response.finish
  end

  def self.should_process?(request)
    false
  end

  def call
    raise "Subclass should implement!"
  end

end

