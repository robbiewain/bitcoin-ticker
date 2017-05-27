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
      expect(ENV).to receive(:[]).with("BITCOIN_PRICE_THRESHOLD").and_return "10"
      expect(ENV).to receive(:[]).with("ETHEREUM_PRICE_THRESHOLD").and_return "1"
      allow(ENV).to receive(:[]).with("SLACK_WEBHOOK_URL").and_return slack_webhook_url
      allow(ticker).to receive(:price_checker) { price_checker }
      expect(price_checker).to receive(:current_price).with(:btc) { current_btc_price }
      expect(price_checker).to receive(:current_price).with(:eth) { current_eth_price }
      allow(ticker).to receive(:price_saver) { price_saver }
      expect(price_saver).to receive(:read).with(:btc) { previous_btc_price }
      expect(price_saver).to receive(:read).with(:eth) { previous_eth_price }
      allow(ticker).to receive(:slack_notifier).and_return slack_notifier
    end
    context "price rise" do
      let(:current_btc_price) { 100 }
      let(:current_eth_price) { 10 }
      let(:previous_btc_price) { 50 }
      let(:previous_eth_price) { 5 }
      it "notifies slack when price and saves new price" do
        expect(slack_notifier).to receive(:notify).with :btc, 100, true
        expect(slack_notifier).to receive(:notify).with :eth, 10, true
        expect(price_saver).to receive(:write).with :btc, 100
        expect(price_saver).to receive(:write).with :eth, 10
        ticker.tick
      end
      context "less than threshold" do
        let(:current_btc_price) { 45 }
        let(:current_eth_price) { 5.50 }
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
      let(:previous_btc_price) { 100 }
      let(:previous_eth_price) { 10 }
      it "notifies slack when price and saves new price" do
        expect(slack_notifier).to receive(:notify).with :btc, 50, false
        expect(slack_notifier).to receive(:notify).with :eth, 5, false
        expect(price_saver).to receive(:write).with :btc, 50
        expect(price_saver).to receive(:write).with :eth, 5
        ticker.tick
      end
      context "less than threshold" do
        let(:current_btc_price) { 95 }
        let(:current_eth_price) { 9.50 }
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
    end
    it "returns the price" do
      expect(price_checker.current_price(:btc)).to eq price
      expect(price_checker.current_price(:eth)).to eq price
    end
  end

  describe PriceSaver do
    let(:price_saver) { described_class.new }
    before do
       Redis.new.del PriceSaver::REDIS_KEYS[:btc]
       Redis.new.del PriceSaver::REDIS_KEYS[:eth]
    end
    it "starts empty" do
      expect(price_saver.read :btc).to eq 0.0
      expect(price_saver.read :eth).to eq 0.0
    end
    it "saves the price" do
      price = 500.13
      price_saver.write :btc, price
      price_saver.write :eth, price
      expect(price_saver.read :btc).to eq price
      expect(price_saver.read :eth).to eq price
    end
  end

  describe PriceComparer do
    let(:price_comparer) { described_class.new }
    it "returns true if increased more than threshold" do
      expect(price_comparer.compare_to_threshold 10, 20, 5).to be true
    end
    it "returns false if lower than threshold" do
      expect(price_comparer.compare_to_threshold 10, 20, 50).to be false
    end
    it "returns false if equal to threshold" do
      expect(price_comparer.compare_to_threshold 10, 20, 10).to be false
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
    let(:btc_username) { "bitcoin-ticker" }
    let(:eth_username) { "ethereum-ticker" }
    let(:btc_payload) { "{\"text\":\"#{btc_text}\",\"username\":\"#{btc_username}\"}" }
    let(:eth_payload) { "{\"text\":\"#{eth_text}\",\"username\":\"#{eth_username}\"}" }
    before do
      allow(ENV).to receive(:[]).with("SLACK_WEBHOOK_URL").and_return webhook_url
      expect(Net::HTTP).to receive(:post_form).with URI(webhook_url), payload: btc_payload
      expect(Net::HTTP).to receive(:post_form).with URI(webhook_url), payload: eth_payload
    end
    it "posts current price to slack" do
      slack_notifier.notify :btc, current_price, true
      slack_notifier.notify :eth, current_price, true
    end
    context "price drop" do
      let(:btc_text) { "Bitcoin is down to $#{current_price}" }
      let(:eth_text) { "Ethereum is down to $#{current_price}" }
      it "posts current price to slack" do
        slack_notifier.notify :btc, current_price, false
        slack_notifier.notify :eth, current_price, false
      end
    end
  end
end
