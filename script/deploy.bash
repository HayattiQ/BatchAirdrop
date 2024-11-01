#!/bin/bash
forge create src/BatchAirdrop.sol:BatchAirdrop --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --verify \
  --constructor-args $TOKEN_ADDRESS $VERSION