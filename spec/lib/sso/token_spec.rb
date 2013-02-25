require 'spec_helper'

describe SSO::Token do
  let(:default_scope) { SSO.config.default_scope } # :user

  before :each do
    SSO::Token.current_token = nil
  end

  describe "self.create" do
    it "creates a new token" do
      token = SSO::Token.create(Rack::Request.new({}))
      SSO::Token.find(token.key).should_not be_nil
    end

    it "calls populate" do
      mock = mock(:request, host: "www.google.com", fullpath: "/search?q=apples")
      SSO::Token.any_instance.should_receive(:populate).with(mock)
      token = SSO::Token.create(mock)
    end
  end

  describe "self.find" do
    it "returns nil if key doesn't exist" do
      SSO::Token.find("notatoken").should be_nil
    end

    it "returns the token if key exists" do
      token = SSO::Token.new
      token.save

      SSO::Token.find(token.key).should == token
    end

    it "doesn't call the cache if passed a nil key" do
      Rails.cache.should_not_receive(:read)

      SSO::Token.find(nil)
    end
  end

  describe "self.identify" do
    before do
      SSO::Token.current_token = SSO::Token.create(mock(:request, host: "google.com", fullpath: "/"))
    end

    it "sets the current token's identity" do
      SSO::Token.identify(5)
      SSO::Token.current_token.identity.should eq(5)
    end

    it "returns true if current token's identity is set" do
      SSO::Token.identify(6).should be_true
    end

    it "returns false if there is no current token" do
      SSO::Token.current_token = nil
      SSO::Token.identify(7).should be_false
    end

    it "saves the token" do
      SSO::Token.identify(8)
      SSO::Token.find(SSO::Token.current_token.key).identity.should eq(8)
    end

    it "sets default_scope id on token session" do
      SSO::Token.identify(9)
      SSO::Token.current_token.session["#{default_scope}_id"].should eq(9)
    end

    context "with scope" do
      it "sets the given scope as attribute in the session" do
        SSO::Token.identify(10, scope: :admin)
        SSO::Token.current_token.session["admin_id"].should eq(10)
        SSO::Token.current_token.identity(:admin).should eq(10)
      end

      it "does not set default scope identity" do
        SSO::Token.identify(11, scope: :admin)
        default_scope.should_not eq(:admin)
        SSO::Token.current_token.identity.should be_nil
        SSO::Token.current_token.identity(default_scope).should be_nil
        SSO::Token.current_token.session["#{default_scope}_id"].should be_nil
      end

      it "sets identity and session id if given scope is default scope" do
        SSO::Token.identify(12, scope: default_scope)
        SSO::Token.current_token.identity.should eq(12)
        SSO::Token.current_token.identity(:user).should eq(12)
        SSO::Token.current_token.session["#{default_scope}_id"].should eq(12)
      end
    end
  end

  describe "self.dismiss" do
    before do
      SSO::Token.current_token = SSO::Token.create(mock(:request, host: "google.com", fullpath: "/"))
    end

    it "returns false if no current_token" do
      SSO::Token.current_token = nil
      SSO::Token.dismiss.should be_false
    end

    it "removes scoped identity" do
      SSO::Token.identify(13, scope: :admin)
      SSO::Token.dismiss(:admin)
      SSO::Token.current_token.identity(:admin).should be_nil
    end

    it "removes scoped identities and retains default identity" do
      SSO::Token.identify(16)
      SSO::Token.identify(17, scope: :admin)

      SSO::Token.dismiss(:admin)
      SSO::Token.current_token.identity.should eq(16)
      SSO::Token.current_token.identity(default_scope).should eq(16)
      SSO::Token.current_token.identity(:admin).should be_nil
    end

    it "removes all scoped identities if removing default scope" do
      SSO::Token.identify(14, scope: default_scope)
      SSO::Token.identify(15, scope: :admin)

      SSO::Token.dismiss(default_scope)
      SSO::Token.current_token.identity.should be_nil
      SSO::Token.current_token.identity(default_scope).should be_nil
      SSO::Token.current_token.identity(:admin).should be_nil
    end

    it "removes all scoped identities if no explicit scope" do
      SSO::Token.identify(14, scope: default_scope)
      SSO::Token.identify(15, scope: :admin)

      SSO::Token.dismiss(default_scope)
      SSO::Token.current_token.identity.should be_nil
      SSO::Token.current_token.identity(default_scope).should be_nil
      SSO::Token.current_token.identity(:admin).should be_nil
    end
  end

  describe "self.find_by_identity" do
    let(:token) { SSO::Token.new }

    it "returns empty array if no existing tokens associated with id" do
      SSO::Token.find_by_identity(123).should be_empty
    end

    it "returns empty array if associated token(s) expired" do
      SSO::Token.current_token = token
      SSO::Token.identify(123)
      token.destroy

      SSO::Token.find_by_identity(123).should be_empty
    end

    it "returns existing associated tokens" do
      SSO::Token.current_token = token
      SSO::Token.identify(123)

      SSO::Token.find_by_identity(123).should eq([token])
    end

    it "returns empty if previously associated token gets re-identified" do
      SSO::Token.current_token = token
      SSO::Token.identify(123)
      SSO::Token.identify(456)

      SSO::Token.find_by_identity(456).should eq([token])
      SSO::Token.find_by_identity(123).should be_empty
    end
  end

  describe "initialize" do
    it "creates a key" do
      SSO::Token.new.key.should_not be_nil
    end

    it "creates an originator_key" do
      SSO::Token.new.originator_key.should_not be_nil
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
      token.populate(mock(:request, host: "www.google.com", fullpath: "/search?q=apples"))
      token.request_domain.should == "www.google.com"
      token.request_path.should   == "/search?q=apples"
    end
  end

  describe "#update" do
    it "updates to match another token" do
      token = SSO::Token.create(mock(:request, host: "www.google.com", fullpath: "/search?q=apples"))
      token.identity = 5

      new_token = SSO::Token.new
      new_token.update(token)
      new_token.request_domain.should == "www.google.com"
      new_token.request_path.should   == "/search?q=apples"
      new_token.originator_key.should == token.originator_key
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
    let(:token) { SSO::Token.new }

    it "returns true if keys match" do
      token.should == SSO::Token.new("key" => token.key)
    end

    it "returns false if keys are different" do
      token.should_not == SSO::Token.new("key" => "different key")
    end

    it "returns false if other token is nil" do
      token.should_not == nil
    end

    it "returns false if not a token" do
      token.should_not == mock(:token, key: token.key)
    end
  end

  describe "#identity" do
    let(:token) { SSO::Token.new }

    it "returns nil if none set" do
      token.identity.should be_nil
    end

    it "returns identity for scope if set" do
      token.identify(16, scope: :admin)
      token.identity(:admin).should eq(16)
    end

    it "returns default scope identity if no scope given" do
      token.identify(17)
      token.identity.should eq(17)
      token.identity(default_scope).should eq(17)
    end

    it "returns default scope identity if default scope" do
      token.identify(17, scope: default_scope)
      token.identity.should eq(17)
      token.identity(default_scope).should eq(17)
    end
  end

  describe "#dismiss" do
    let(:token) { SSO::Token.new }

    it "removes scoped identity" do
      token.identify(13, scope: :admin)

      token.dismiss(:admin)

      token.identity(:admin).should be_nil
    end

    it "removes scoped identities and retains default identity" do
      token.identify(16)
      token.identify(17, scope: :admin)

      token.dismiss(:admin)

      token.identity.should eq(16)
      token.identity(default_scope).should eq(16)
      token.identity(:admin).should be_nil
    end

    it "removes all scoped identities if removing default scope" do
      token.identify(14, scope: default_scope)
      token.identify(15, scope: :admin)

      token.dismiss(default_scope)

      token.identity.should be_nil
      token.identity(default_scope).should be_nil
      token.identity(:admin).should be_nil
    end

    it "removes all scoped identities if no explicit scope" do
      token.identify(18, scope: default_scope)
      token.identify(19, scope: :admin)

      token.dismiss(default_scope)

      token.identity.should be_nil
      token.identity(default_scope).should be_nil
      token.identity(:admin).should be_nil
    end

    it "destroys token if logging out all scopes on central domain" do
      token.identify(20)
      token.should_receive(:destroy)

      token.dismiss(domain: SSO.config.central_domain)

      token.identity.should be_nil
    end

    it "does not destroy token if optional domain does not match central domain" do
      token.identify(20)
      token.should_not_receive(:destroy)

      token.dismiss(domain: "example.com")

      token.identity.should be_nil
    end

    it "does not destroy token if not logging out all scopes" do
      token.identify(20)
      token.identify(20, scope: :admin)
      token.should_not_receive(:destroy)

      token.dismiss(:admin, domain: SSO.config.central_domain)

      token.identity.should eq(20)
      token.identity(:admin).should be_nil
    end

  end

end
