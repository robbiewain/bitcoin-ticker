require "net/http"
require "json"

module BitcoinTicker
  class PriceChecker
    COINBASE_SPOT_PRICE_URI = "https://api.coinbase.com/v2/prices/spot"

    def current_price
      begin
        res = Net::HTTP.get_response(URI(COINBASE_SPOT_PRICE_URI))
        json = JSON.parse(res.body)
        json["data"]["amount"].to_f
      rescue Exception => e
        puts e.message
      end
    end
  end
end
