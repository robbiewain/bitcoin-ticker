require "net/http"
require "json"

module BitcoinTicker
  class PriceChecker
    PRICE_URIS = {
      btc: "https://api.coinbase.com/v2/prices/spot",
      eth: "https://poloniex.com/public?command=returnTicker"
    }

    def current_price(ticker)
      json = get_price_data PRICE_URIS[ticker]
      send "parse_#{ticker}_json".to_sym, json
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

    def parse_btc_json(json)
      json["data"]["amount"].to_f
    end

    def parse_eth_json(json)
      json["USDT_ETH"]["last"].to_f
    end
  end
end
