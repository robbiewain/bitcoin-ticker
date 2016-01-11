require "net/http"
require "json"

module BitcoinTicker
  class PriceChecker
    Error = Class.new(StandardError)

    COINBASE_SPOT_PRICE_URI = "https://api.coinbase.com/v2/prices/spot"

    def initialize(coinbase_spot_price_uri: COINBASE_SPOT_PRICE_URI)
      self.coinbase_spot_price_uri = URI(coinbase_spot_price_uri)
    end

    def current_price
      begin
        res = Net::HTTP.get_response(coinbase_spot_price_uri)
        json = JSON.parse(res.body)
        json["data"]["amount"].to_f
      rescue Exception => e
        raise PriceChecker, "[PriceChecker#current_price] Error: #{e.message}"
      end
    end

    private
    attr_accessor :coinbase_spot_price_uri
  end
end
