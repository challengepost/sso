require 'spec_helper'

describe SSO::Token do
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
end
