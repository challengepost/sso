SSO.config.central_domain = "centraldomain.com"

Rails.application.config.middleware.use SSO::Middleware::Authenticate
