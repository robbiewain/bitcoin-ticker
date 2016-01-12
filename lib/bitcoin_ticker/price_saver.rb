require "redis"

module BitcoinTicker
  class PriceSaver
    DEFAULT_REDIS_KEY = "bitcoin-price"

    def initialize(client: Redis.new, key: DEFAULT_REDIS_KEY)
      self.client = client
      self.key = key
    end

    def read
      client.get(key).to_f
    end

    def write(current_price)
      client.set(key, current_price)
    end

    private
    attr_accessor :key, :client
  end
end
