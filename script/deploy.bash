#!/bin/bash

# envファイルを読み込む
source .env

forge create src/BatchAirdrop.sol:BatchAirdrop --private-key $PRIVATE_KEY \
  --rpc-url $RPC_ENDPOINT \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --verify \
  --constructor-args $TOKEN_ADDRESS $VERSION