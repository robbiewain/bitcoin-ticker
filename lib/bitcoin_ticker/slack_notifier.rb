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
    ICON_URLS = {
      btc: "https://en.bitcoin.it/w/images/en/2/29/BC_Logo_.png",
      eth: "https://www.ethereum.org/images/logos/ETHEREUM-ICON_Black.png"
    }

    def notify(ticker, current_price, price_increased)
      payload = {
        text: "#{FULLNAMES[ticker]} is #{price_increased ? "up" : "down"} to $#{"%.2f" % current_price}",
        username: USERNAMES[ticker],
        icon_url: ICON_URLS[ticker]
      }
      Net::HTTP.post_form(URI(ENV["SLACK_WEBHOOK_URL"]), payload: payload.to_json)
    end
  end
end
