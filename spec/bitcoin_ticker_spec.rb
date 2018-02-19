require "spec_helper"
require "bitcoin_ticker.rb"

module BitcoinTicker
  describe BitcoinTicker do
    let(:ticker) { BitcoinTicker.new }
    let(:slack_webhook_url) { "https://hooks.slack.com/services/123/123" }
    let(:slack_notifier) { double "Slack Notifier" }
    let(:price_saver) { double "Price Saver" }
    let(:price_checker) { double "Price Checker" }
    before do
      allow(ENV).to receive(:[]).with("PERCENT_CHANGE_THRESHOLD").and_return("10")
      allow(ENV).to receive(:[]).with("SLACK_WEBHOOK_URL").and_return(slack_webhook_url)
      allow(ticker).to receive(:price_checker) { price_checker }
      allow(price_checker).to receive(:current_price).with(:btc) { current_btc_price }
      allow(price_checker).to receive(:current_price).with(:eth) { current_eth_price }
      allow(price_checker).to receive(:current_price).with(:ltc) { current_ltc_price }
      allow(price_checker).to receive(:current_price).with(:neo) { current_neo_price }
      allow(ticker).to receive(:price_saver) { price_saver }
      allow(price_saver).to receive(:read).with(:btc) { previous_btc_price }
      allow(price_saver).to receive(:read).with(:eth) { previous_eth_price }
      allow(price_saver).to receive(:read).with(:ltc) { previous_ltc_price }
      allow(price_saver).to receive(:read).with(:neo) { previous_neo_price }
      allow(ticker).to receive(:slack_notifier).and_return(slack_notifier)
    end
    context "price rise" do
      let(:current_btc_price) { 100 }
      let(:current_eth_price) { 10 }
      let(:current_ltc_price) { 10 }
      let(:current_neo_price) { 10 }
      let(:previous_btc_price) { 50 }
      let(:previous_eth_price) { 5 }
      let(:previous_ltc_price) { 3 }
      let(:previous_neo_price) { 3 }
      it "notifies slack when price and saves new price" do
        expect(slack_notifier).to receive(:notify).with(:btc, 100, true)
        expect(slack_notifier).to receive(:notify).with(:eth, 10, true)
        expect(slack_notifier).to receive(:notify).with(:ltc, 10, true)
        expect(slack_notifier).to receive(:notify).with(:neo, 10, true)
        expect(price_saver).to receive(:write).with(:btc, 100)
        expect(price_saver).to receive(:write).with(:eth, 10)
        expect(price_saver).to receive(:write).with(:ltc, 10)
        expect(price_saver).to receive(:write).with(:neo, 10)
        ticker.tick
      end
      context "less than threshold" do
        let(:current_btc_price) { 49 }
        let(:current_eth_price) { 5.10 }
        let(:current_ltc_price) { 3.10 }
        let(:current_neo_price) { 3.10 }
        it "doesn't notify slack or save the new price" do
          expect(slack_notifier).not_to receive(:notify)
          expect(price_saver).not_to receive(:write)
          ticker.tick
        end
      end
    end
    context "price drop" do
      let(:current_btc_price) { 50 }
      let(:current_eth_price) { 5 }
      let(:current_ltc_price) { 3 }
      let(:current_neo_price) { 3 }
      let(:previous_btc_price) { 100 }
      let(:previous_eth_price) { 10 }
      let(:previous_ltc_price) { 10 }
      let(:previous_neo_price) { 10 }
      it "notifies slack when price and saves new price" do
        expect(slack_notifier).to receive(:notify).with(:btc, 50, false)
        expect(slack_notifier).to receive(:notify).with(:eth, 5, false)
        expect(slack_notifier).to receive(:notify).with(:ltc, 3, false)
        expect(slack_notifier).to receive(:notify).with(:neo, 3, false)
        expect(price_saver).to receive(:write).with(:btc, 50)
        expect(price_saver).to receive(:write).with(:eth, 5)
        expect(price_saver).to receive(:write).with(:ltc, 3)
        expect(price_saver).to receive(:write).with(:neo, 3)
        ticker.tick
      end
      context "less than threshold" do
        let(:current_btc_price) { 95 }
        let(:current_eth_price) { 9.50 }
        let(:current_ltc_price) { 9.30 }
        let(:current_neo_price) { 9.10 }
        it "doesn't notify slack or save the new price" do
          expect(slack_notifier).not_to receive(:notify)
          expect(price_saver).not_to receive(:write)
          ticker.tick
        end
      end
    end
  end

  describe PriceChecker do
    let(:price_checker) { described_class.new }
    let(:price) { 1000 }
    before do
      expect(Net::HTTP).to receive(:get_response)
        .with(URI(PriceChecker::PRICE_URIS[:btc]))
        .and_return(OpenStruct.new status: 200, body: "{ \"data\": { \"amount\": \"#{price}\" } }")
      expect(Net::HTTP).to receive(:get_response)
        .with(URI(PriceChecker::PRICE_URIS[:eth]))
        .and_return(OpenStruct.new status: 200, body: "{ \"data\": { \"amount\": \"#{price}\" } }")
      expect(Net::HTTP).to receive(:get_response)
        .with(URI(PriceChecker::PRICE_URIS[:ltc]))
        .and_return(OpenStruct.new status: 200, body: "{ \"data\": { \"amount\": \"#{price}\" } }")
      expect(Net::HTTP).to receive(:get_response)
        .with(URI(PriceChecker::PRICE_URIS[:neo]))
        .and_return(OpenStruct.new status: 200, body: "[ { \"price_usd\": \"#{price}\" } ]")
    end
    it "returns the price" do
      expect(price_checker.current_price(:btc)).to eq price
      expect(price_checker.current_price(:eth)).to eq price
      expect(price_checker.current_price(:ltc)).to eq price
      expect(price_checker.current_price(:neo)).to eq price
    end
  end

  describe PriceSaver do
    let(:price_saver) { described_class.new }
    before do
       Redis.new.del PriceSaver::REDIS_KEYS[:btc]
       Redis.new.del PriceSaver::REDIS_KEYS[:eth]
       Redis.new.del PriceSaver::REDIS_KEYS[:ltc]
       Redis.new.del PriceSaver::REDIS_KEYS[:neo]
    end
    it "starts empty" do
      expect(price_saver.read :btc).to eq 0.0
      expect(price_saver.read :eth).to eq 0.0
      expect(price_saver.read :ltc).to eq 0.0
      expect(price_saver.read :neo).to eq 0.0
    end
    it "saves the price" do
      price = 500.13
      price_saver.write :btc, price
      price_saver.write :eth, price
      price_saver.write :ltc, price
      price_saver.write :neo, price
      expect(price_saver.read :btc).to eq price
      expect(price_saver.read :eth).to eq price
      expect(price_saver.read :ltc).to eq price
      expect(price_saver.read :neo).to eq price
    end
  end

  describe PriceComparer do
    let(:price_comparer) { described_class.new }
    it "returns true if increased more than threshold" do
      expect(price_comparer.compare_to_threshold 10, 20, 5).to be true
    end
    it "returns false if lower than threshold" do
      expect(price_comparer.compare_to_threshold 10, 14, 50).to be false
    end
    it "returns false if equal to threshold" do
      expect(price_comparer.compare_to_threshold 10, 11, 10).to be false
    end
    it "returns true if descreased more than threshold" do
      expect(price_comparer.compare_to_threshold 20, 10, 5).to be true
    end
  end

  describe SlackNotifier do
    let(:slack_notifier) { described_class.new }
    let(:current_price) { 123.45 }
    let(:webhook_url) { "https://slack.com/webhook_url/123" }
    let(:btc_text) { "Bitcoin is up to $#{current_price}" }
    let(:eth_text) { "Ethereum is up to $#{current_price}" }
    let(:ltc_text) { "Litecoin is up to $#{current_price}" }
    let(:neo_text) { "Neo is up to $#{current_price}" }
    let(:btc_username) { "bitcoin-ticker" }
    let(:eth_username) { "ethereum-ticker" }
    let(:ltc_username) { "litecoin-ticker" }
    let(:neo_username) { "neo-ticker" }
    let(:btc_payload) { "{\"text\":\"#{btc_text}\",\"username\":\"#{btc_username}\"}" }
    let(:eth_payload) { "{\"text\":\"#{eth_text}\",\"username\":\"#{eth_username}\"}" }
    let(:ltc_payload) { "{\"text\":\"#{ltc_text}\",\"username\":\"#{ltc_username}\"}" }
    let(:neo_payload) { "{\"text\":\"#{neo_text}\",\"username\":\"#{neo_username}\"}" }
    before do
      allow(ENV).to receive(:[]).with("SLACK_WEBHOOK_URL").and_return webhook_url
      expect(Net::HTTP).to receive(:post_form).with URI(webhook_url), payload: btc_payload
      expect(Net::HTTP).to receive(:post_form).with URI(webhook_url), payload: eth_payload
      expect(Net::HTTP).to receive(:post_form).with URI(webhook_url), payload: ltc_payload
      expect(Net::HTTP).to receive(:post_form).with URI(webhook_url), payload: neo_payload
    end
    it "posts current price to slack" do
      slack_notifier.notify :btc, current_price, true
      slack_notifier.notify :eth, current_price, true
      slack_notifier.notify :ltc, current_price, true
      slack_notifier.notify :neo, current_price, true
    end
    context "price drop" do
      let(:btc_text) { "Bitcoin is down to $#{current_price}" }
      let(:eth_text) { "Ethereum is down to $#{current_price}" }
      let(:ltc_text) { "Litecoin is down to $#{current_price}" }
      let(:neo_text) { "Neo is down to $#{current_price}" }
      it "posts current price to slack" do
        slack_notifier.notify :btc, current_price, false
        slack_notifier.notify :eth, current_price, false
        slack_notifier.notify :ltc, current_price, false
        slack_notifier.notify :neo, current_price, false
      end
    end
  end
end
