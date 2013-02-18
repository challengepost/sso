require 'securerandom'

class SSO::Token
  extend SSO::Callbacks

  EXPIRES_IN = 1_209_600 # 2 weeks

  cattr_accessor :current_token

  attr_reader :key, :originator_key, :session, :request_domain, :request_path
  attr_accessor :identity, :previous_identity

  def self.find(key)
    load(redis.get(key))
  end

  def self.create(request)
    token = new
    token.populate(request)
    token.save
    token
  end

  # Public: Associate and save a user id with the current sso token.
  #
  # identity  - The Integer id to be save.
  #
  # Examples
  #
  #   SSO::Token.identify(123)
  #   # => <SSO::Token>
  #
  # Returns the current token if successful.
  def self.identify(identity, opts = {})
    ActiveRecord::Base.logger.info("identifying: #{identity} for current_token #{current_token.inspect}")
    return false unless current_token

    current_token.identify(identity, opts)
  end

  def self.dismiss(*scopes)
    return false unless current_token

    current_token.dismiss(*scopes)
  end

  # Public: Return existing tokens matching given identity.
  #
  # Examples
  #
  #   SSO::Token.find_by_identity(id)
  #   # => [<SSO::Token...>, <SSO::Token...>]
  #
  # Returns Array.
  def self.find_by_identity(identity)
    possible_keys = IdentityHistory.sso_keys(identity)
    return [] if possible_keys.empty?

    possible_tokens = redis.mget(*possible_keys).map { |value| load(value) }.compact
    possible_tokens.select { |token| token.identity == identity }
  end

  def self.load(redis_value = nil)
    return nil if redis_value.nil?
    new(ActiveSupport::JSON.decode(redis_value.to_s))
  end

  def self.current_token=(token)
    # ActiveSupport::Deprecation.warn("SSO::Token.current_token is now deprecated")
    @@current_token = token
  end

  def self.redis
    SSO.config.redis
  end

  def self.default_scope
    SSO.config.default_scope
  end

  def initialize(attributes = {})
    @key            = attributes["key"] || SecureRandom::hex(50)
    @originator_key = attributes["originator_key"] || SecureRandom::hex(50)
    @request_domain = attributes["request_domain"]
    @request_path   = attributes["request_path"]
    @identity       = attributes["identity"]
    @session        = ActiveSupport::JSON.decode(attributes["session"] || "{}")
  end

  def save
    identity_history.save(self)

    redis.set(@key, to_json)
    redis.expire(@key, EXPIRES_IN)
    self
  end

  def populate(request)
    @request_domain = request.host
    @request_path   = request.fullpath
  end

  def update(token)
    @request_domain = token.request_domain
    @request_path   = token.request_path
    @originator_key = token.originator_key
    save
  end

  def destroy
    redis.del(@key)
  end

  def ==(token)
    token && key == token.key && token.is_a?(SSO::Token)
  end

  def identity(scope = default_scope)
    if scope == default_scope
      @identity
    else
      session[session_scope_key(scope)]
    end
  end

  def identify(id, opts = {})
    scope = opts[:scope] || default_scope

    @identity = id if scope == default_scope
    session["#{scope}_id"] = id
    save
  end

  def dismiss(*scopes)
    if scopes.empty? || scopes == [default_scope]
      scopes = all_scopes
    end

    scopes.each do |scope|
      @identity = nil if scope == default_scope
      session[session_scope_key(scope)] = nil
    end

    if scopes == all_scopes
      destroy
    else
      save
    end
  end

  def identity_history
    IdentityHistory.new(@identity)
  end

private

  def to_json
    { key: key,
      originator_key: originator_key,
      request_domain: request_domain,
      request_path: request_path,
      identity: identity,
      session: session.to_json
    }.to_json
  end

  def redis
    self.class.redis
  end

  def default_scope
    self.class.default_scope
  end

  def session_scope_key(scope)
    "#{scope}_id"
  end

  def all_scopes
    session_scopes = session.keys.grep(/.*_id/) { |key| key.gsub("_id", "") }.map(&:to_sym)
    Set.new(session_scopes).tap do |scopes|
      scopes << :user if @identity # ensure user scope is set for legacy purposes
    end
  end

  # Public: Store sso keys for a given identity in redis set
  #
  class IdentityHistory
    def self.redis
      SSO.config.redis
    end

    def self.sso_keys(identity)
      redis.smembers(redis_key(identity))
    end

    def self.redis_key(identity)
      "sso:identity:#{identity}"
    end

    attr_reader :identity

    def initialize(identity)
      @identity = identity
    end

    def save(token)
      return false unless identity

      redis.sadd(redis_key, token.key)
      redis.expire(@key, EXPIRES_IN)
    end

    private

    def redis
      self.class.redis
    end

    def redis_key
      self.class.redis_key(identity)
    end
  end

end
