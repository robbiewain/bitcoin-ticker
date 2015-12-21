require "redis"

module BitcoinTicker
  class PriceSaver
    REDIS_KEY = "bitcoin-price"

    def initialize
      @redis = Redis.new
    end

    def read
      @redis.get(REDIS_KEY).to_f
    end

    def write(current_price)
      @redis.set(REDIS_KEY, current_price)
    end
  end
end
