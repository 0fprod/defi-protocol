
local:
    @forge script script/DeployEngine.s.sol:DeployEngine -- --fork-url http://localhost:8545 --broadcast
    
deployEngine:
	@forge create --rpc-url ${SEPOLIA_RPC_URL} \
    --constructor-args [0xdd13E55209Fd76AfE204dBda4007C227904f0a81,0x779877A7B0D9E8603169DdbD7836e478b4624789] [0x694AA1769357215DE4FAC081bf1f309aDC325306,0xc59E3633BAAC79493d908e63626716e204A45EdF] 0x9f3c6AfEe5b66D51Ea005EeA4591Ca65b4630Ef8 \
    --private-key ${PRIVATE_KEY} \
    --etherscan-api-key ${ETHERSCAN_API_KEY} \
    --verify src/DSCEngine.sol:DSCEngine

deployCoin:
	@forge create --rpc-url ${SEPOLIA_RPC_URL} \
    --constructor-args 0x9D3052DB3062d60643682B1272d00a6bF4A6f5E6 \
    --private-key ${PRIVATE_KEY} \
    --etherscan-api-key ${ETHERSCAN_API_KEY} \
    --verify \
    src/DSCoin.sol:DSCoin

verifyCoin:
    @forge verify-contract \
    --chain-id 11155111 \
    --num-of-optimizations 200 \
    --watch \
    --constructor-args $(cast abi-encode "constructor(address)" 0x9D3052DB3062d60643682B1272d00a6bF4A6f5E6) \
    --etherscan-api-key ${ETHERSCAN_API_KEY} \
    --compiler-version v0.8.21+commit.d9974bed \
    0x9f3c6AfEe5b66D51Ea005EeA4591Ca65b4630Ef8 ./src/DSCoin.sol:DSCoin

verifyEngine:
    @forge verify-contract \
    --chain-id 11155111 \
    --num-of-optimizations 200 \
    --watch \
    --constructor-args $(cast abi-encode "constructor(address[],address[],address)" [0xdd13E55209Fd76AfE204dBda4007C227904f0a81,0x779877A7B0D9E8603169DdbD7836e478b4624789] [0x694AA1769357215DE4FAC081bf1f309aDC325306,0xc59E3633BAAC79493d908e63626716e204A45EdF] 0x9f3c6AfEe5b66D51Ea005EeA4591Ca65b4630Ef8) \
    --etherscan-api-key ${ETHERSCAN_API_KEY} \
    --compiler-version v0.8.21+commit.d9974bed \
    0x533EB9D0240A8F8f044581BE10E7487119d6307A ./src/DSCEngine.sol:DSCEngine
