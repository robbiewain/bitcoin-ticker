require "net/http"

module BitcoinTicker
  class SlackNotifier
    FULLNAMES = {
      btc: "Bitcoin",
      eth: "Ethereum"
    }
    USERNAMES = {
      btc: "bitcoin-ticker",
      eth: "ethereum-ticker"
    }
    ICON_EMOJIS = {
      btc: ":bitcoin:",
      eth: ":ethereum:"
    }

    def notify(ticker, current_price, price_increased)
      payload = {
        text: "#{FULLNAMES[ticker]} is #{price_increased ? "up" : "down"} to $#{"%.2f" % current_price}",
        username: USERNAMES[ticker],
        icon_emoji: ICON_EMOJIS[ticker]
      }
      Net::HTTP.post_form(URI(ENV["SLACK_WEBHOOK_URL"]), payload: payload.to_json)
    end
  end
end
