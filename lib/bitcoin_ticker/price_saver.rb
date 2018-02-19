require "redis"

module BitcoinTicker
  class PriceSaver
    REDIS_KEYS = {
      btc: "bitcoin-price",
      bch: "bitcoin-cash-price",
      eth: "ethereum-price",
      ltc: "litecoin-price",
      neo: "neo-price"
    }

    def read(ticker)
      redis.get(REDIS_KEYS[ticker]).to_f
    end

    def write(ticker, current_price)
      redis.set(REDIS_KEYS[ticker], current_price)
    end

    private

    def redis
      @redis ||= Redis.new
    end
  end
end
