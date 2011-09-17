module SSO
  class Token
    cattr_accessor :current_token

    attr_reader :key, :originator_key, :request_domain, :request_path
    attr_accessor :identity

    # TODO Move to storage (e.g. redis)
    @@tokens = {}

    def self.find(key)
      @@tokens[key]
    end

    def self.create(request)
      token = new
      token.populate(request)
      token.save
      token
    end

    def self.identify(id)
      if current_token
        current_token.identity = id
        current_token.save
      else
        false
      end
    end

    def initialize
      @key            = ActiveSupport::SecureRandom::hex(50)
      @originator_key = ActiveSupport::SecureRandom::hex(50)
    end

    def save
      @@tokens[@key] = self
    end

    def populate(request)
      @request_domain = request.host
      @request_path   = request.fullpath
    end

    def update(token)
      @request_domain = token.request_domain
      @request_path   = token.request_path
      @identity       = token.identity
    end

    def destroy
      @@tokens[key] = nil
    end

    def ==(token)
      key == token.key if token
    end
  end
end
