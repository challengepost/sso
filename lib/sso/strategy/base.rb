class SSO::Strategy::Base

  attr_reader :app, :request

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

  def self.should_process?(request)
    false
  end

  def call
    raise "Subclass should implement!"
  end

end

