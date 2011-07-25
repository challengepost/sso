module SSO
  class Token
    attr_reader :key

    # TODO Move to storage (e.g. redis)
    @@keys = []

    def self.find(key)
      @@keys.include?(key) ? new(key) : nil
    end

    def initialize(existing_key = nil)
      @key = existing_key

      unless @key
        @key = ActiveSupport::SecureRandom::hex(50)
        @@keys << @key
      end
    end

    def ==(token)
      key == token.key
    end
  end
end
