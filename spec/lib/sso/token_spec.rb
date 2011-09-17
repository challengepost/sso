require 'spec_helper'

describe SSO::Token do
  describe ".new_for" do
    it "creates a new token" do
      token = SSO::Token.new_for(Rack::Request.new({}))
      SSO::Token.find(token.key).should_not be_nil
    end

    it "calls populate!" do
      mock = mock(:request, :host => "www.google.com", :fullpath => "/search?q=apples")
      SSO::Token.any_instance.should_receive(:populate!).with(mock)
      token = SSO::Token.new_for(mock)
    end
  end

  describe "initialize" do
    it "creates a key" do
      SSO::Token.new.key.should_not be_nil
    end

    it "inserts new token into list" do
      token = SSO::Token.new
      SSO::Token.find(token.key).should_not be_nil
    end
  end

  describe "find" do
    it "returns nil if key doesn't exist" do
      SSO::Token.find("notatoken").should be_nil
    end

    it "returns the token if key exists" do
      token = SSO::Token.new
      SSO::Token.find(token.key).should == token
    end
  end

  describe "#populate!" do
    it "populates based on request" do
      token = SSO::Token.new
      token.populate!(mock(:request, :host => "www.google.com", :fullpath => "/search?q=apples"))
      token.request_domain.should == "www.google.com"
      token.request_path.should   == "/search?q=apples"
    end
  end

  describe "#update!" do
    it "updates to match another token" do
      token = SSO::Token.new_for(mock(:request, :host => "www.google.com", :fullpath => "/search?q=apples"))
      new_token = SSO::Token.new
      new_token.update!(token)
      new_token.request_domain.should == "www.google.com"
      new_token.request_path.should   == "/search?q=apples"
    end
  end

  describe "#destroy" do
    it "removes the token" do
      token = SSO::Token.new
      token.destroy
      SSO::Token.find(token.key).should be_nil
    end
  end

  describe "#==" do
    before do
      @token = SSO::Token.new
    end

    it "returns true if keys match" do
      @token.should == mock(:token, :key => @token.key)
    end

    it "returns false if keys are different" do
      @token.should_not == mock(:token, :key => "different key")
    end

    it "returns false if other token is nil" do
      @token.should_not == nil
    end
  end
end
