require 'spec_helper'

describe SSO::Token do
  describe ".create" do
    it "creates a new token" do
      token = SSO::Token.create(Rack::Request.new({}))
      SSO::Token.find(token.key).should_not be_nil
    end

    it "calls populate" do
      mock = mock(:request, :host => "www.google.com", :fullpath => "/search?q=apples")
      SSO::Token.any_instance.should_receive(:populate).with(mock)
      token = SSO::Token.create(mock)
    end
  end

  describe ".find" do
    it "returns nil if key doesn't exist" do
      SSO::Token.find("notatoken").should be_nil
    end

    it "returns the token if key exists" do
      token = SSO::Token.new
      token.save

      SSO::Token.find(token.key).should == token
    end
  end

  describe ".identify" do
    before do
      SSO::Token.current_token = SSO::Token.create(mock(:request, :host => "google.com", :fullpath => "/"))
    end

    it "sets the current token's identity" do
      SSO::Token.identify(5)

      SSO::Token.current_token.identity.should == 5
    end

    it "returns true if current token's identity is set" do
      SSO::Token.identify(5).should be_true
    end

    it "returns false if there is no current token" do
      SSO::Token.current_token = nil

      SSO::Token.identify(5).should be_false
    end

    it "saves the token" do
      SSO::Token.identify(5)

      SSO::Token.find(SSO::Token.current_token.key).identity.should == 5
    end
  end

  describe "initialize" do
    it "creates a key" do
      SSO::Token.new.key.should_not be_nil
    end

    it "creates an originator_key" do
      SSO::Token.new.originator_key.should_not be_nil
    end

    it "creates a csrf_token" do
      SSO::Token.new.csrf_token.should_not be_nil
    end
  end

  describe "#save" do
    it "inserts new token into list" do
      token = SSO::Token.new
      token.save
      SSO::Token.find(token.key).should_not be_nil
    end
  end

  describe "#populate" do
    it "populates based on request" do
      token = SSO::Token.new
      token.populate(mock(:request, :host => "www.google.com", :fullpath => "/search?q=apples"))
      token.request_domain.should == "www.google.com"
      token.request_path.should   == "/search?q=apples"
    end
  end

  describe "#update" do
    it "updates to match another token" do
      token = SSO::Token.create(mock(:request, :host => "www.google.com", :fullpath => "/search?q=apples"))
      token.identity = 5

      new_token = SSO::Token.new
      new_token.update(token)
      new_token.request_domain.should == "www.google.com"
      new_token.request_path.should   == "/search?q=apples"
      new_token.csrf_token.should     == token.csrf_token
      new_token.identity.should       == 5
    end
  end

  describe "#destroy" do
    it "removes the token" do
      token = SSO::Token.new
      token.destroy
      SSO::Token.find(token.key).should be_nil
    end
  end

  describe "#session" do
    it "defaults to an empty hash" do
      SSO::Token.new.session.should == {}
    end

    it "persists sso session data" do
      token = SSO::Token.new
      token.session[:isAwesome?] = true
      token.save

      SSO::Token.find(token.key).session["isAwesome?"].should be_true
    end
  end

  describe "==" do
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
