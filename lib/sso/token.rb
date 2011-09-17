module SSO
  class Token
    attr_reader :key, :originator_key, :request_domain, :request_path

    # TODO Move to storage (e.g. redis)
    @@tokens = {}

    def self.find(key)
      @@tokens[key]
    end

    def self.new_for(request)
      new.tap do |token|
        token.populate!(request)
      end
    end

    def initialize(existing_key = nil)
      @key = existing_key

      unless @key
        @key = ActiveSupport::SecureRandom::hex(50)
        @originator_key = ActiveSupport::SecureRandom::hex(50)
        @@tokens[@key] = self
      end
    end

    def populate!(request)
      @request_domain = request.host
      @request_path = request.fullpath
    end

    def update!(token)
      @request_domain = token.request_domain
      @request_path = token.request_path
    end

    def destroy
      @@tokens[key] = nil
    end

    def ==(token)
      key == token.key
    end
  end
end
