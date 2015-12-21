require "net/http"

module BitcoinTicker
  class SlackNotifier
    def notify(webhook_url, current_price, price_increased)
      uri = URI(webhook_url)
      payload = {
        text: "Bitcoin is #{price_increased ? "up" : "down"} to $#{"%.2f" % current_price}",
        username: "bitcoin-ticker",
        icon_url: "https://en.bitcoin.it/w/images/en/2/29/BC_Logo_.png"
      }
      Net::HTTP.post_form(uri, payload: payload.to_json)
    end
  end
end
