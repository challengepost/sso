require 'spec_helper'

describe SSO do
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
  end
end
