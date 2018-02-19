require "redis"

module BitcoinTicker
  class PriceSaver
    def read(ticker)
      redis.get("#{ticker}-price").to_f
    end

    def write(ticker, current_price)
      redis.set("#{ticker}-price", current_price)
    end

    private

    def redis
      @redis ||= Redis.new
    end
  end
end
