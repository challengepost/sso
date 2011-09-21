require 'spec_helper'

describe SSO::Middleware::Authenticate do
  before do
    @session = SessionCookie.new
  end

  describe "Normal request" do
    context "Visitor doesn't have a token on the client domain" do
      before do
        SSO::Token.should_receive(:create).and_return(mock(:token, :key => "new_token", :originator_key => "12345"))
        get "/"
      end

      it "redirects to the authenticate url on the central domain with a new token" do
        last_response.status.should == 302
        last_response.headers["Location"].should == "http://centraldomain.com/sso/auth/new_token"
      end

      it "doesn't set current_token" do
        SSO::Token.current_token.should be_nil
      end
    end

    context "visitor is a bot" do
      before do
        get "/", {}, { 'HTTP_USER_AGENT' => "Googlebot" }
      end

      it "passes through to the app if visitor is a bot" do
        last_response.status.should == 200
        last_response.body.should =~ /Ruby on Rails: Welcome aboard/
      end

      it "doesn't set current_token" do
        SSO::Token.current_token.should be_nil
      end
    end

    context "Visitor has a valid token" do
      before do
        @token = SSO::Token.new
        @token.save

        @session[:sso_token] = @token.key
        set_cookie @session.to_s

        get "/"
      end

      it "passes through to the app" do
        last_response.status.should == 200
        last_response.body.should =~ /Ruby on Rails: Welcome aboard/
      end

      it "sets current_token" do
        SSO::Token.current_token.should == @token
      end

      it "sets the csrf_token to the token's csrf_token" do
        SessionCookie.parse(last_response)["_csrf_token"].should == @token.csrf_token
      end

      it "doesn't bleed current_token into the next request" do
        clear_cookies
        @session[:sso_token] = nil
        set_cookie @session.to_s

        get "/?sso=notarealtoken"

        SSO::Token.current_token.should be_nil
      end
    end

    context "Visitor has an invalid token" do
      before do
        SSO::Token.should_receive(:create).and_return(mock(:token, :key => "new_token", :originator_key => "12345"))

        get "/", {}, { 'rack.session' =>  { :sso_token => 'notarealtoken' } }
      end

      it "redirects to the authenticate url on the central domain with a new token" do
        last_response.status.should == 302
        last_response.headers["Location"].should == "http://centraldomain.com/sso/auth/new_token"
      end

      it "doesn't set the current token" do
        SSO::Token.current_token.should be_nil
      end
    end

    context "valid sso parameter is present" do
      before do
        @token = SSO::Token.create(mock(:request, :host => "example.com", :fullpath => "/"))
        @session[:originator_key] = @token.originator_key
        set_cookie @session.to_s
      end

      it "stores the token in the session" do
        get "/?sso=#{@token.key}"

        SessionCookie.parse(last_response)["sso_token"].should == @token
      end

      it "redirects back to the same url without the sso parameter" do
        get "/?sso=#{@token.key}"

        last_response.status.should == 302
        last_response.headers["Location"].should == "http://example.com/"
      end

      it "doesn't set current_token" do
        get "/?sso=#{@token.key}"

        SSO::Token.current_token.should be_nil
      end

      context "originator keys don't match" do
        before do
          @session[:originator_key] = "different_originator_key"
          set_cookie @session.to_s
          get "/?sso=#{@token.key}"
        end

        it "passes through to the app" do
          last_response.status.should == 200
          last_response.body.should =~ /Ruby on Rails: Welcome aboard/
        end

        it "doesn't set current_token" do
          SSO::Token.current_token.should be_nil
        end
      end
    end

    context "invalid sso parameter is present" do
      before do
        get "/?sso=notarealtoken"
      end

      it "passes through to the app" do
        last_response.status.should == 200
        last_response.body.should =~ /Ruby on Rails: Welcome aboard/
      end

      it "doesn't set current_token" do
        SSO::Token.current_token.should be_nil
      end
    end
  end

  describe "Auth requests" do
    context "token is valid" do
      before do
        @token = SSO::Token.create(mock(:request, :host => "example.com", :fullpath => "/some/path"))

        get "/sso/auth/#{@token.key}"
      end

      it "stores the token in the central domain's session" do
        SessionCookie.parse(last_response)["sso_token"].should == @token.key
      end

      it "redirects back to the client domain with the new token as a parameter" do
        last_response.status.should == 302
        last_response.headers["Location"].should == "http://example.com/some/path?sso=#{@token.key}"
      end

      it "doesn't set current_token" do
        SSO::Token.current_token.should be_nil
      end
    end

    context "token isn't valid" do
      before do
        get "/sso/auth/notarealtoken", {}, { 'HTTP_REFERER' => "http://clientdomain.com/some/path" }
      end

      it "redirects back to the client domain if token isn't valid" do
        last_response.status.should == 302
        last_response.headers["Location"].should == "http://clientdomain.com/some/path"
      end

      it "doesn't set current_token" do
        SSO::Token.current_token.should be_nil
      end
    end

    context "Visitor has an existing token on the central domain" do
      before do
        @existing_token = SSO::Token.create(mock(:request, :host => "example.com", :fullpath => "/some/path"))
        @session[:sso_token] = @existing_token.key
        set_cookie @session.to_s

        @token = SSO::Token.create(mock(:request, :host => "anotherexample.com", :fullpath => "/some/other/path"))
        get "/sso/auth/#{@token.key}"
      end

      it "updates existing token with data from the new token" do
        SSO::Token.find(@existing_token.key).request_domain.should == "anotherexample.com"
        SSO::Token.find(@existing_token.key).request_path.should == "/some/other/path"
      end

      it "deletes the new token" do
        SSO::Token.find(@token.key).should be_false
      end

      it "redirects back to the client domain with the existing token as a parameter" do
        last_response.status.should == 302
        last_response.headers["Location"].should == "http://anotherexample.com/some/other/path?sso=#{@existing_token.key}"
      end

      it "doesn't set current_token" do
        SSO::Token.current_token.should be_nil
      end
    end
  end
end
