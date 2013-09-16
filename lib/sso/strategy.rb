module SSO
  module Strategy
    extend ActiveSupport::Autoload

    autoload :Base
    autoload :DisableRedirect
    autoload :ExistingTokenViaRedirect
    autoload :ExistingTokenViaParam
    autoload :ExistingTokenViaSession
    autoload :NewToken
    autoload :Skip
  end
end
