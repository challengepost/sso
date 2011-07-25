require 'spec_helper'

class TestApp
  def self.call(env)
    [200, {"Content-Type" => "text/plain"}, ["Test"]]
  end
end

describe SSO::Middleware::Authenticate do
  def app
    SSO::Middleware::Authenticate.new(TestApp)
  end

  describe "Normal request" do
    context "Visitor doesn't have a token on the client domain" do
      it "redirects to the authenticate url on the central domain with a new token" do
        SSO::Token.should_receive(:new).and_return(mock(:token, :key => "new_token"))

        get "/"

        last_response.status.should == 302
        last_response.headers["Location"].should == "http://centraldomain.com/sso/auth/new_token"
      end

      it "returns the result of TestApp if visitor is a bot" do
        get "/", {}, { 'HTTP_USER_AGENT' => "Googlebot" }

        last_response.status.should == 200
        last_response.body.should == "Test"
      end
    end

    context "Visitor has a valid token" do
      it "returns the result of TestApp" do
        token = SSO::Token.new

        get "/", {}, { 'rack.session' =>  { :sso_token => token.key } }

        last_response.status.should == 200
        last_response.body.should == "Test"
      end
    end

    context "Visitor has an invalid token" do
      it "redirects to the authenticate url on the central domain with a new token" do
        SSO::Token.should_receive(:new).and_return(mock(:token, :key => "new_token"))

        get "/", {}, { 'rack.session' =>  { :sso_token => 'notarealtoken' } }

        last_response.status.should == 302
        last_response.headers["Location"].should == "http://centraldomain.com/sso/auth/new_token"
      end
    end
  end
end

