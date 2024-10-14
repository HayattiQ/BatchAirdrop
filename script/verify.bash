forge verify-contract 0xc59ed4521f0627d0470975c6285841271062f6e1 \
 src/BatchAirdrop.sol:BatchAirdrop \
 --chain-id 8453 \
 --watch \
 --etherscan-api-key $ETHERSCAN_API_KEY \
 --constructor-args $(cast  abi-encode "constructor(address)" "$TOKEN_ADDRESS")