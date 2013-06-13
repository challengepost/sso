module AppHelper
  def app
    Dummy::Application
  end

  def mock_request(url = "/", opts = {})
    env = Rack::MockRequest.env_for(url, opts)
    Rack::Request.new(env)
  end
end
