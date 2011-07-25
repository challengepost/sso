require 'spec_helper'

describe SSO::Middleware::Authenticate do
  class TestApp
    def self.call(env)
      default_response
    end

    def self.default_response
      [200, {"Content-Type" => "text/plain"}, ["Test"]]
    end
  end

  def app
    SSO::Middleware::Authenticate.new(TestApp)
  end

  describe "call" do
    it "returns the result of the passed app's call" do
      TestApp.should_receive(:call).and_return(TestApp.default_response)

      get "/"

      last_response.status.should == 200
      last_response.body.should == "Test"
    end
  end
end

