class SSO::Token
  cattr_accessor :current_token

  attr_reader :key, :originator_key, :session, :request_domain, :request_path, :csrf_token
  attr_accessor :identity

  def self.find(key)
    value = SSO.config.redis.get(key)
    new(ActiveSupport::JSON.decode(value)) if value
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

  def initialize(attributes = {})
    @key            = attributes["key"] || SecureRandom::hex(50)
    @originator_key = attributes["originator_key"] || SecureRandom::hex(50)
    @csrf_token     = attributes["csrf_token"] || SecureRandom.base64(32)
    @request_domain = attributes["request_domain"]
    @request_path   = attributes["request_path"]
    @identity       = attributes["identity"]
    @session        = ActiveSupport::JSON.decode(attributes["session"] || "{}")
  end

  def save
    SSO.config.redis.set(@key, to_json)
    SSO.config.redis.expire(@key, 1_209_600) # 2 weeks
  end

  def populate(request)
    @request_domain = request.host
    @request_path   = request.fullpath
  end

  def update(token)
    @request_domain = token.request_domain
    @request_path   = token.request_path
    @originator_key = token.originator_key
    @csrf_token     = token.csrf_token
    save
  end

  def destroy
    SSO.config.redis.del(@key)
  end

  def ==(token)
    key == token.key if token
  end

private

  def to_json
    { :key => key,
      :originator_key => originator_key,
      :request_domain => request_domain,
      :request_path => request_path,
      :csrf_token => csrf_token,
      :identity => identity,
      :session => session.to_json
    }.to_json
  end
end
