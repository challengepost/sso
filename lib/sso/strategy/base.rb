class SSO::Strategy::Base
  def initialize(app, env, request)
    @app, @env, @request = app, env, request
  end

  def redirect_to(url)
    response = Rack::Response.new
    response.redirect(url)
    response.finish
  end

end

