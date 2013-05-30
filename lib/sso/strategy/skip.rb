class SSO::Strategy::Skip < SSO::Strategy::Base

  class << self

    def should_process?(request)
      skip_path?(request) || is_bot?(request) || skip_request?(request)
    end

    def skip_path?(request)
      SSO.config.skip_paths.any? { |skip_path| skip_path_match?(skip_path, request.path) }
    end

    def is_bot?(request)
      (request.user_agent =~ SSO.config.robots).tap do |matches|
        ActiveRecord::Base.logger.info "Request for apparent bot" if matches
      end
    end

    def skip_request?(request)
      SSO.config.skip_request_methods.any? { |method| method.call(request) }
    end

    def skip_path_match?(skip_path, request_path)
      case skip_path
      when Regexp
        skip_path =~ request_path
      else # String
        skip_path == request_path
      end
    end
  end

  def call(env)
    app.call(env)
  end

end
