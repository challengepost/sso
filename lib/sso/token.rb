require 'securerandom'

class SSO::Token
  cattr_accessor :current_token

  attr_reader :key, :originator_key, :session, :request_domain, :request_path
  attr_accessor :identity

  def self.find(key)
    value = redis.get(key)
    new(ActiveSupport::JSON.decode(value.to_s)) if value
  end

  def self.create(request)
    token = new
    token.populate(request)
    token.save
    token
  end

  def self.identify(id)
    if current_token
      current_token.identity = id
      current_token.save
    else
      false
    end
  end

  def self.redis
    SSO.config.redis
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
    redis.set(@key, to_json)
    redis.expire(@key, 1_209_600) # 2 weeks
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
end
