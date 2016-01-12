require "net/http"

module BitcoinTicker
  class SlackNotifier
    DEFAULT_TEXT_FMT = ->(price, increased) {
      "Bitcoin is #{increased ? "up" : "down"} to $#{"%.2f" % price}"
    }
    DEFAULT_USERNAME = "bitcoin-ticker"
    DEFAULT_ICON_URL = "https://en.bitcoin.it/w/images/en/2/29/BC_Logo_.png"

    def initialize(webhook_url:, text: DEFAULT_TEXT_FMT, username: DEFAULT_USERNAME, icon_url: DEFAULT_ICON_URL)
      self.webhook_url = webhook_url
      self.text        = text
      self.username    = username
      self.icon_url    = icon_url
    end

    # call-seq:
    #   notifier.notify(current_price, price_increased)
    #
    # Parameters:
    #   * current_price   [Float] : Current BTC price
    #   * price_increased [Bool]  : Whether or not this price was price increase
    def notify(current_price, price_increased)
      payload = {
        text:     text.call(current_price, price_increased),
        username: username,
        icon_url: icon_url
      }

      http_call
    end

    def http_call
      uri = URI(webhook_url)
      Net::HTTP.post_form(uri, payload: payload.to_json)
    end

    private
    attr_accessor :webhook_url, :username, :icon_url, :text
  end
end
