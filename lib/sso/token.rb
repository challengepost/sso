class SSO::Token
  cattr_accessor :current_token

  attr_reader :key, :originator_key, :session, :request_domain, :request_path, :csrf_token
  attr_accessor :identity

  def self.find(key)
    value = Rails.cache.read(key) if key
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
    @key            = attributes["key"] || ActiveSupport::SecureRandom::hex(50)
    @originator_key = attributes["originator_key"] || ActiveSupport::SecureRandom::hex(50)
    @csrf_token     = attributes["csrf_token"] || ActiveSupport::SecureRandom.base64(32)
    @request_domain = attributes["request_domain"]
    @request_path   = attributes["request_path"]
    @identity       = attributes["identity"]
    @session        = ActiveSupport::JSON.decode(attributes["session"] || "{}")
  end

  def save
    Rails.cache.write(@key, to_json)
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
    Rails.cache.delete(@key)
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
