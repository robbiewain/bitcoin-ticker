require "net/http"
require "json"

module BitcoinTicker
  class PriceChecker
    PRICE_URIS = {
      btc: "https://api.coinbase.com/v2/prices/BTC-USD/spot",
      eth: "https://api.coinbase.com/v2/prices/ETH-USD/spot",
      ltc: "https://api.coinbase.com/v2/prices/LTC-USD/spot",
      neo: "https://api.coinmarketcap.com/v1/ticker/neo/"
    }

    def current_price(ticker)
      uri = PRICE_URIS[ticker]
      json = get_price_data(uri)
      if uri =~ /api.coinbase.com/
        json["data"]["amount"].to_f
      elsif uri =~ /api.coinmarketcap.com/
        json.first["price_usd"].to_f
      end
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
