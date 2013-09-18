require 'spec_helper'

describe SSO::Middleware::Authentication do
  before do
    @session = SessionCookie.new
  end

  describe "SSO redirect disabled" do
    before do
      SSO.config.disable_redirect = true
    end

    context "Visitor doesn't have a token on the client domain" do
      let(:valid_token) { mock(:token, key: "new_token", originator_key: "12345") }

      before do
        SSO::Token.stub!(:create).and_return(valid_token)
        get "/"
      end

      it "does not redirect" do
        last_response.status.should == 200
        last_response.body.should =~ /Ruby on Rails: Welcome aboard/
      end

      it "sets current_token" do
        last_request.env['current_sso_token'].should eq(valid_token)
        SSO::Token.current_token.should eq(valid_token)
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

    end

    context "Visitor has an invalid token" do
      let(:valid_token) { mock(:token, key: "new_token", originator_key: "12345") }

      before do
        SSO::Token.should_receive(:create).and_return(valid_token)

        get "/", {}, { 'rack.session' =>  { sso_token: 'notarealtoken' } }
      end

      it "redirects to the authenticate url on the central domain with a new token" do
        last_response.status.should == 200
        last_response.body.should =~ /Ruby on Rails: Welcome aboard/
      end

      it "doesn't set the current token" do
        last_request.env['current_sso_token'].should eq(valid_token)
        SSO::Token.current_token.should eq(valid_token)
      end
    end
  end
end
