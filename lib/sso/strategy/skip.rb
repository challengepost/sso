class SSO::Strategy::Skip < SSO::Strategy::Base

  class << self
    def should_process?(request)
      skip_path?(request) || is_bot?(request)
    end

    def skip_path?(request)
      path = request.path
      SSO.config.skip_paths.select do |p|
        p.is_a?(String) ? path == p : path =~ p
      end.any?
    end

    def is_bot?(request)
      (request.user_agent =~ SSO.config.robots).tap do |matches|
        ActiveRecord::Base.logger.info "Request for apparent bot" if matches
      end
    end
  end

  def call
    @app.call(@env)
  end

end