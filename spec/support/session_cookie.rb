class SessionCookie
  extend Forwardable
  def_delegators :session_hash, :[], :[]=

  attr_reader :session_hash, :cookie_store, :request

  DEFAULT_ENV = {
    'action_dispatch.secret_token' => Dummy::Application.config.secret_token,
    'rack.session.options' => { :domain=>nil, :httponly=>true, :path=>"/", :secure=>false, :expire_after=>nil }
  }

  SESSION_KEY = Dummy::Application.config.session_options[:key]

  def self.build(driver)
    new driver.last_request.env
  rescue Rack::Test::Error
    driver.get '/'
    retry
  end

  def self.parse(response)
    session = CGI::Cookie::parse(response.headers['Set-Cookie'])[SESSION_KEY].first
    ActiveSupport::MessageVerifier.new(Dummy::Application.config.secret_token).verify(session)
  end

  def initialize(env = {})
    env.merge!(DEFAULT_ENV)

    @cookie_store = ActionDispatch::Session::CookieStore.new Dummy::Application
    @session_hash  = ActionDispatch::Session::AbstractStore::SessionHash.new cookie_store, env
    @request = ActionDispatch::Request.new(env)
  end

  def to_s
    "#{SESSION_KEY}=#{signed_session_value};"
  end

  def signed_session_value
    request.cookie_jar.signed[SESSION_KEY] = {:value => session_hash.to_hash}
    Rack::Utils.escape(request.cookie_jar[SESSION_KEY])
  end
end
