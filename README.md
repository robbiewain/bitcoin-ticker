# BitcoinTicker

A Bitcoin/Ethereum ticker that sends price changes to Slack

## Installation

Install Redis

## Configuration

The bitcoin/ethereum ticker will only notify Slack if the bitcoin/ethereum price changes by more than the threshold. To set the bitcoin threshold to $10 and the ethereum threshold to $1:
```
export BITCOIN_PRICE_THRESHOLD=10
export ETHEREUM_PRICE_THRESHOLD=1
```

A Slack webhook url is used to send the update to Slack. For example:
```
export SLACK_WEBHOOK_URL=https://hooks.slack.com/services/123/123
```

## Run
```
bundle exec ruby bin/bitcoin-ticker
```
