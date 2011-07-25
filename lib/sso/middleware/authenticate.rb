module SSO
  module Middleware
    class Authenticate
      def initialize(app)
        @app = app
      end

      def call(env)
        request = Rack::Request.new(env)

        if is_bot?(request) || SSO::Token.find(request.session[:sso_token])
          @app.call(env)
        else
          response = Rack::Response.new
          response.redirect "http://centraldomain.com/sso/auth/#{SSO::Token.new.key}"
          response.finish
        end
      end

    private

      # TODO move to a configuration option
      # checks the user agent against a list of bots
      # http://gurge.com/blog/2007/01/08/turn-off-rails-sessions-for-robots/
      def is_bot?(request)
        request.user_agent =~ /\b(Baidu|Gigabot|Googlebot|libwww-perl|lwp-trivial|msnbot|SiteUptime|Slurp|WordPress|ZIBB|ZyBorg|UnwindFetchor|TweetmemeBot|Voyager|yahoo\.com|Birubot|MetaURI|Twitterbot|PycURL|PostRank|Twitmunin)\b/i
      end
      # From Baidu to ZyBord: search engines
      # From UnwindFetchor to Twitmunin: twitter bots and twitter related hits
    end
  end
end
