module SSO
  module Callbacks
    def on_request(&block)
      on_request_callbacks << block
    end

    def on_request_callbacks
      @on_request_callbacks ||= []
    end

    def run_callbacks(token)
      on_request_callbacks.each do |callback|
        callback.call(token)
      end
    end
  end
end
