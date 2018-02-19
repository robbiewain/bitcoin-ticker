require "net/http"

module BitcoinTicker
  class SlackNotifier
    FULLNAMES = {
      btc: "Bitcoin",
      bch: "Bitcoin Cash",
      eth: "Ethereum",
      ltc: "Litecoin",
      neo: "Neo"
    }
    USERNAMES = {
      btc: "bitcoin-ticker",
      bch: "bitcoin-cash-ticker",
      eth: "ethereum-ticker",
      ltc: "litecoin-ticker",
      neo: "neo-ticker"
    }

    def notify(ticker, current_price, price_increased)
      payload = {
        text: "#{FULLNAMES[ticker]} is #{price_increased ? "up" : "down"} to $#{"%.2f" % current_price}",
        username: USERNAMES[ticker]
      }
      Net::HTTP.post_form(URI(ENV["SLACK_WEBHOOK_URL"]), payload: payload.to_json)
    end
  end
end
