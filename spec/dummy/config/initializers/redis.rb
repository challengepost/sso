require 'redis'
require 'mock_redis'
$redis = MockRedis.new

# Extensions to mock_redis gem
class MockRedis
  class Database

    # Not currently implemented in the mock_redis
    # gem so we add our own implementation which
    # currently assumes #sort is called on a redis list
    def sort(key, options = {})
      with_list_at(key, &:sort)
    end

    # mock_redis implementation had issues with
    # our use of #expire in the SSO gem so we're
    # stubbing this method instead
    def expire(key, seconds)
      # no-op
    end

  end
end

