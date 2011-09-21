class SSO::Middleware::Authenticate
  def initialize(app)
    @app = app
  end

  def call(env)
    SSO::Token.current_token = nil

    request = Rack::Request.new(env)

    if skip_sso?(request.path)
      @app.call(env)
    elsif request.path =~ /^\/sso\/auth/
      authenticate(request, env)
    elsif request.params['sso']
      verify(request, env)
    elsif verified?(request)
      request.session[:_csrf_token] = SSO::Token.current_token.csrf_token if SSO::Token.current_token
      @app.call(env)
    else
      redirect_to_central(request, env)
    end
  end

private

  def skip_sso?(path)
    SSO.config.skip_paths.select{ |p| path.index(p) == 0 }.any?
  end

  def verified?(request)
    is_bot?(request) || SSO::Token.current_token = SSO::Token.find(request.session[:sso_token])
  end

  def authenticate(request, env)
    if token = SSO::Token.find(request.path.gsub("/sso/auth/", ""))
      if existing_token = SSO::Token.find(request.session[:sso_token])
        existing_token.update(token)
        token.destroy
        token = existing_token
      end

      request.session[:sso_token] = token.key
      redirect_to "http://#{token.request_domain}#{token.request_path}#{token.request_path.match(/\?/) ? "&sso=" : "?sso="}#{token.key}"
    else
      redirect_to request.referrer
    end
  end

  def verify(request, env)
    if request.session[:originator_key] && token = SSO::Token.find(request.params['sso'])
      if request.session[:originator_key] == token.originator_key
        request.session[:sso_token] = token
        redirect_to "http://#{token.request_domain}#{token.request_path}"
      else
        @app.call(env)
      end
    else
      @app.call(env)
    end
  end

  def redirect_to_central(request, env)
    token = SSO::Token.create(request)
    request.session[:originator_key] = token.originator_key
    redirect_to "http://#{SSO.config.central_domain}/sso/auth/#{token.key}"
  end

  # TODO move to a configuration option
  # checks the user agent against a list of bots
  # http://gurge.com/blog/2007/01/08/turn-off-rails-sessions-for-robots/
  def is_bot?(request)
    request.user_agent =~ /\b(Baidu|Gigabot|Googlebot|libwww-perl|lwp-trivial|msnbot|SiteUptime|Slurp|WordPress|ZIBB|ZyBorg|UnwindFetchor|TweetmemeBot|Voyager|yahoo\.com|Birubot|MetaURI|Twitterbot|PycURL|PostRank|Twitmunin)\b/i
  end
  # From Baidu to ZyBord: search engines
  # From UnwindFetchor to Twitmunin: twitter bots and twitter related hits

  def redirect_to(url)
    response = Rack::Response.new
    response.redirect(url)
    response.finish
  end
end
