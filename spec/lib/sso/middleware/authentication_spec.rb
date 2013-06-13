require 'spec_helper'

describe SSO::Middleware::Authentication do
  before do
    @session = SessionCookie.new
  end

  describe "Normal request" do
    context "Visitor doesn't have a token on the client domain" do
      let (:token) {
        SSO::Token.new({
          "key" => "new_token",
          "originator_key" => "12345",
          "request_url" => "http://example.com"
        })
      }
      it "redirects to the authenticate url on the central domain with a new token" do
        SSO::Token.stub!(:create).and_return(token)
        get "/"
        last_response.status.should == 302
        last_response.headers["Location"].should == "http://centraldomain.com/sso/auth/new_token"
      end

      it "doesn't set current_token" do
        SSO::Token.stub!(:create).and_return(token)
        get "/"
        last_request.env['current_sso_token'].should be_nil
        SSO::Token.current_token.should be_nil
      end

      context "new visit, following redirects" do
        def follow_sso_redirects!
          # follow redirect for new token
          # follow redirect for setting session on central domain
          # follow redirect for setting session on satellite domain
          3.times { follow_redirect! }
        end

        it "for new token" do
          get "/"
          follow_sso_redirects!
          last_response.status.should == 200
          last_response.body.should =~ /Ruby on Rails: Welcome aboard/
        end

        it "for additional params" do
          get "/", { 'foo' => 'bar' }
          follow_sso_redirects!
          last_request.params.should eq({ "foo" => "bar" })
          last_request.scheme.should eq("http")
        end

        it "for https request url" do
          get "https://example.com/", { 'foo' => 'bar' }
          follow_sso_redirects!
          last_request.params.should eq({ "foo" => "bar" })
          last_request.scheme.should eq("https")
        end

        it "request /sso/identity, not logged in on central domain" do
          get "/sso/identity"
          follow_sso_redirects!
          last_response.status.should == 401
          last_response.body.should =~ /You are not logged in/
        end

        it "request /sso/identity, logged in on central domain" do
          SSO.on_next_request do |current_token|
            current_token.identify "123" # mimic logged in user
          end

          get "/sso/identity"

          follow_sso_redirects!

          last_response.status.should == 200
          last_response.body.should =~ /You are logged in as User 123/
        end
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
        last_request.env['current_sso_token'].should be_nil
        SSO::Token.current_token.should be_nil
      end

      it "logs to the Rails.logger" do
        log.should include("Request for apparent bot")
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
        last_request.env['current_sso_token'].should eq(@token)
      end

      it "logs to the Rails.logger" do
        log.should include("Request for token: #{@token.key}")
      end

      it "doesn't bleed current_token into the next request" do
        clear_cookies
        @session[:sso_token] = nil
        set_cookie @session.to_s

        get "/?sso=notarealtoken"

        last_request.env['current_sso_token'].should be_nil
        SSO::Token.current_token.should be_nil
      end
    end

    context "Visitor has an invalid token" do
      before do
        SSO::Token.should_receive(:create).and_return(mock(:token, key: "new_token", originator_key: "12345"))

        get "/", {}, { 'rack.session' =>  { sso_token: 'notarealtoken' } }
      end

      it "redirects to the authenticate url on the central domain with a new token" do
        last_response.status.should == 302
        last_response.headers["Location"].should == "http://centraldomain.com/sso/auth/new_token"
      end

      it "doesn't set the current token" do
        last_request.env['current_sso_token'].should be_nil
        SSO::Token.current_token.should be_nil
      end
    end

    context "valid sso parameter is present" do
      let(:request) { mock_request("http://example.com/") }

      before do
        @token = SSO::Token.create(request)
        @session[:originator_key] = @token.originator_key
        set_cookie @session.to_s
      end

      it "stores the token in the session" do
        get "/?sso=#{@token.key}"

        SessionCookie.parse(last_response)["sso_token"].should == @token.key
      end

      it "redirects back to the same url without the sso parameter" do
        get "/?sso=#{@token.key}"

        last_response.status.should == 302
        last_response.headers["Location"].should == "http://example.com/"
      end

      it "doesn't set current_token" do
        get "/?sso=#{@token.key}"

        last_request.env['current_sso_token'].should be_nil
        SSO::Token.current_token.should be_nil
      end

      it "logs to the Rails.logger" do
        get "/?sso=#{@token.key}"

        log.should include("Setting session token: #{@token.key}")
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
          last_request.env['current_sso_token'].should be_nil
          SSO::Token.current_token.should be_nil
        end

        it "logs to the Rails.logger" do
          log.should include("Originator key didn't match while verifying token: #{@token.key}")
        end
      end

      context "missing originator key" do
        before do
          @session[:originator_key] = nil
          set_cookie @session.to_s
          get "/?sso=#{@token.key}"
        end

        it "passes through to the app" do
          last_response.status.should == 200
          last_response.body.should =~ /Ruby on Rails: Welcome aboard/
        end

        it "doesn't set current_token" do
          last_request.env['current_sso_token'].should be_nil
          SSO::Token.current_token.should be_nil
        end

        it "logs to the Rails.logger" do
          log.should include("No session originator key found while verifying token: #{@token.key}")
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
        last_request.env['current_sso_token'].should be_nil
        SSO::Token.current_token.should be_nil
      end

      it "logs to the Rails.logger" do
        log.should include("Invalid token while attempting to verify: notarealtoken")
      end
    end
  end

  describe "Auth requests" do
    let(:request) { mock_request("http://example.com/some/path") }
    context "token is valid" do
      before do
        @token = SSO::Token.create(request)

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
        last_request.env['current_sso_token'].should be_nil
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
        last_request.env['current_sso_token'].should be_nil
        SSO::Token.current_token.should be_nil
      end

      it "logs to the Rails.logger" do
        log.should include("Invalid token while authenticating")
      end
    end

    context "Visitor has an existing token on the central domain" do
      before do
        request_1 = mock_request("http://example.com/some/path")
        @existing_token = SSO::Token.create(request)
        @session[:sso_token] = @existing_token.key
        set_cookie @session.to_s

        request_2 = mock_request("http://anotherexample.com/some/other/path")
        @token = SSO::Token.create(request_2)
        get "/sso/auth/#{@token.key}"
      end

      it "updates existing token with data from the new token" do
        SSO::Token.find(@existing_token.key).request_url.should == "http://anotherexample.com/some/other/path"
      end

      it "deletes the new token" do
        SSO::Token.find(@token.key).should be_false
      end

      it "redirects back to the client domain with the existing token as a parameter" do
        last_response.status.should == 302
        last_response.headers["Location"].should == "http://anotherexample.com/some/other/path?sso=#{@existing_token.key}"
      end

      it "doesn't set current_token" do
        last_request.env['current_sso_token'].should be_nil
        SSO::Token.current_token.should be_nil
      end

      it "logs to the Rails.logger" do
        log.should include("Existing token found: #{@existing_token.key}")
      end
    end
  end
end
