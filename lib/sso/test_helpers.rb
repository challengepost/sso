module SSO
  module TestHelpers
    def on_next_request(&block)
      next_request_commands << block
    end

    def next_request_commands
      @next_request_commands ||= []
    end

    def test_reset!
      next_request_commands.clear
    end
  end
end

