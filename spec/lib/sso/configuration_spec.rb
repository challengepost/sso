require 'spec_helper'

describe SSO do
  let(:mock_token) { mock(:token, key: "new_token", originator_key: "12345") }

  describe "central_domain" do
    it "requires a central_domain to be set" do
      SSO.config.central_domain = nil

      lambda { get "/" }.should raise_error
    end
  end

  describe "redis" do
    it "requires redis to be populated" do
      SSO.config.redis = nil

      lambda { get "/" }.should raise_error
    end
  end

  describe "default_scope" do
    it "defaults to :user" do
      SSO.config.default_scope.should eq(:user)
    end

    it "is configurable" do
      SSO.config.default_scope = :admin
      SSO.config.default_scope.should eq(:admin)
    end
  end

  context "skip logic" do
    def last_response_should_skip_sso
      last_response.status.should == 200
      last_response.body.should =~ /Ruby on Rails: Welcome aboard/
    end

    def last_response_should_not_skip_sso
      last_response.status.should == 302
      last_response.headers["Location"].should == "http://centraldomain.com/sso/auth/new_token"
    end

    describe "skip_routes" do
      it "doesn't apply SSO paths in skip_paths" do
        SSO.config.skip_paths = ["/passthrough"]

        get "/passthrough"

        last_response_should_skip_sso
      end

      it "accepts regex skip_paths" do
        SSO.config.skip_paths = [/\/users\/\w+/]

        get "/users/username"

        last_response_should_skip_sso
      end

      it "accepts regex skip_paths that don't match at the root of the path" do
        SSO.config.skip_paths = [/username$/]

        get "/users/username"

        last_response_should_skip_sso
      end

      it "redirects to sso if no skip_paths set" do
        SSO.config.skip_paths = nil

        SSO::Token.should_receive(:create).and_return(mock_token)

        get "/"

        last_response_should_not_skip_sso
      end
    end

    describe "skip block" do
      let(:params) {{}}
      let(:env) {{}}

      before do
        SSO::Token.stub(:create).and_return(mock_token)
      end

      it "skips sso custom skip block resolves true" do
        SSO.configure do |sso|
          sso.skip_request do |request|
            request.host == "api.challengepost.com"
          end
        end
        env["HTTP_HOST"] = "api.challengepost.com"

        get "/", params, env

        last_response_should_skip_sso
      end

      it "redirects to sso if no omissions defined" do
        SSO.configure do |sso|
          sso.skip_request do |request|
            request.host == "api.challengepost.com"
          end
        end
        env["HTTP_HOST"] = "not.api.challengepost.com"

        get "/", params, env

        last_response_should_not_skip_sso
      end

      it "redirects to sso if no omissions defined" do
        get "/", params, env

        last_response_should_not_skip_sso
      end
    end
  end
end
