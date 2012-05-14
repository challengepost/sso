SSO.config.central_domain = "centraldomain.com"
SSO.config.redis = $redis

Rails.application.config.middleware.use SSO::Middleware::Authentication
