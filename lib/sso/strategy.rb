module SSO
  module Strategy
    extend ActiveSupport::Autoload

    autoload :Base
    autoload :Skip
    autoload :ExistingTokenViaRedirect
    autoload :ExistingTokenViaParam
    autoload :ExistingTokenViaSession
    autoload :NewToken
  end
end
