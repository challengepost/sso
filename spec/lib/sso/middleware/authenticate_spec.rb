require 'spec_helper'

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

describe SSO::Middleware::Authenticate do
  def app
    Dummy::Application
  end

  before do
    @session = SessionCookie.new
  end

  describe "Normal request" do
    context "Visitor doesn't have a token on the client domain" do
      it "redirects to the authenticate url on the central domain with a new token" do
        SSO::Token.should_receive(:new).and_return(mock(:token, :key => "new_token", :populate! => true, :originator_key => "12345"))

        get "/"

        last_response.status.should == 302
        last_response.headers["Location"].should == "http://centraldomain.com/sso/auth/new_token"
      end

      it "passes through to the app if visitor is a bot" do
        get "/", {}, { 'HTTP_USER_AGENT' => "Googlebot" }

        last_response.status.should == 200
        last_response.body.should =~ /Ruby on Rails: Welcome aboard/
      end
    end

    context "Visitor has a valid token" do
      it "passes through to the app" do
        token = SSO::Token.new

        @session[:sso_token] = token.key
        set_cookie @session.to_s
        get "/"

        last_response.status.should == 200
        last_response.body.should =~ /Ruby on Rails: Welcome aboard/
      end
    end

    context "Visitor has an invalid token" do
      it "redirects to the authenticate url on the central domain with a new token" do
        SSO::Token.should_receive(:new).and_return(mock(:token, :key => "new_token", :populate! => true, :originator_key => "12345"))

        get "/", {}, { 'rack.session' =>  { :sso_token => 'notarealtoken' } }

        last_response.status.should == 302
        last_response.headers["Location"].should == "http://centraldomain.com/sso/auth/new_token"
      end
    end

    context "valid sso parameter is present" do
      it "stores the token in the session" do
        token = SSO::Token.new
        @session[:originator_key] = token.originator_key
        set_cookie @session.to_s
        get "/?sso=#{token.key}"

        SessionCookie.parse(last_response)["sso_token"].should == token
      end

      it "redirects back to the same url without the sso parameter" do
        token = SSO::Token.new
        token.populate!(mock(:request, :host => "example.com", :fullpath => "/"))
        @session[:originator_key] = token.originator_key
        set_cookie @session.to_s
        get "/?sso=#{token.key}"

        last_response.status.should == 302
        last_response.headers["Location"].should == "http://example.com/"
      end

      it "passes through to the app if originator keys don't match" do
        token = SSO::Token.new

        @session[:originator_key] = "different_originator_key"
        set_cookie @session.to_s
        get "/?sso=#{token.key}"

        last_response.status.should == 200
        last_response.body.should =~ /Ruby on Rails: Welcome aboard/
      end
    end

    context "invalid sso parameter is present" do
      it "passes through to the app" do
        get "/?sso=notarealtoken"

        last_response.status.should == 200
        last_response.body.should =~ /Ruby on Rails: Welcome aboard/
      end
    end
  end

  describe "Auth requests" do
    it "redirects back to the client domain if token isn't valid" do
      get "/sso/auth/notarealtoken", {}, { 'HTTP_REFERER' => "http://clientdomain.com/some/path" }

      last_response.status.should == 302
      last_response.headers["Location"].should == "http://clientdomain.com/some/path"
    end

    it "stores the token in the central domain's session" do
      token = SSO::Token.new
      token.populate!(mock(:request, :host => "example.com", :fullpath => "/some/path"))

      get "/sso/auth/#{token.key}"

      SessionCookie.parse(last_response)["sso_token"].should == token.key
    end

    it "redirects back to the client domain with the new token as a parameter" do
      token = SSO::Token.new
      token.populate!(mock(:request, :host => "example.com", :fullpath => "/some/path"))

      get "/sso/auth/#{token.key}"

      last_response.status.should == 302
      last_response.headers["Location"].should == "http://example.com/some/path?sso=#{token.key}"
    end

    context "Visitor has an existing token on the central domain" do
      before do
        @existing_token = SSO::Token.new
        @existing_token.populate!(mock(:request, :host => "example.com", :fullpath => "/some/path"))
        @session[:sso_token] = @existing_token.key
        set_cookie @session.to_s
      end

      it "updates existing token with data from the new token" do
        token = SSO::Token.new
        token.populate!(mock(:request, :host => "anotherexample.com", :fullpath => "/some/other/path"))

        get "/sso/auth/#{token.key}"

        @existing_token.request_domain.should == "anotherexample.com"
        @existing_token.request_path.should == "/some/other/path"
      end

      it "deletes the new token" do
        token = SSO::Token.new
        token.populate!(mock(:request, :host => "anotherexample.com", :fullpath => "/some/other/path"))

        get "/sso/auth/#{token.key}"

        SSO::Token.find(token.key).should be_false
      end

      it "redirects back to the client domain with the existing token as a parameter" do
        token = SSO::Token.new
        token.populate!(mock(:request, :host => "anotherexample.com", :fullpath => "/some/other/path"))

        get "/sso/auth/#{token.key}"

        last_response.status.should == 302
        last_response.headers["Location"].should == "http://anotherexample.com/some/other/path?sso=#{@existing_token.key}"
      end
    end
  end
end
