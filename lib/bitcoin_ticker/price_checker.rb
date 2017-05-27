require "net/http"
require "json"

module BitcoinTicker
  class PriceChecker
    PRICE_URIS = {
      btc: "https://api.coinbase.com/v2/prices/BTC-USD/spot",
      eth: "https://api.coinbase.com/v2/prices/ETH-USD/spot"
    }

    def current_price(ticker)
      json = get_price_data PRICE_URIS[ticker]
      json["data"]["amount"].to_f
    end

    private

    def get_price_data(uri)
      begin
        res = Net::HTTP.get_response URI(uri)
        JSON.parse(res.body)
      rescue Exception => e
        puts e.message
      end
    end
  end
end
