require 'spec_helper'

describe SSO do
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

  describe "skip_routes" do
    it "doesn't apply SSO paths in skip_paths" do
      SSO.config.skip_paths = ["/passthrough"]

      get "/passthrough"

      last_response.status.should == 200
      last_response.body.should =~ /Ruby on Rails: Welcome aboard/
    end

    it "accepts regex skip_paths" do
      SSO.config.skip_paths = [/\/users\/\w+/]

      get "/users/username"

      last_response.status.should == 200
      last_response.body.should =~ /Ruby on Rails: Welcome aboard/
    end

    it "accepts regex skip_paths that don't match at the root of the path" do
      SSO.config.skip_paths = [/username$/]

      get "/users/username"

      last_response.status.should == 200
      last_response.body.should =~ /Ruby on Rails: Welcome aboard/
    end

    it "works if no skip_paths are defined" do
      SSO.config.skip_paths = nil

      SSO::Token.should_receive(:create).and_return(mock(:token, :key => "new_token", :originator_key => "12345"))

      get "/"

      last_response.status.should == 302
      last_response.headers["Location"].should == "http://centraldomain.com/sso/auth/new_token"
    end
  end
end
