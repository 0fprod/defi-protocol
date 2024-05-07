# Decentralized stablecoin

This protocol was created based on the [Cyfrins Advanced Froundry Course](https://updraft.cyfrin.io/courses/advanced-foundry).

---

### Project Description

This stablecoin called DSC (Decentralized Stable Coin) is ment to be pegged to 1 USD. The protocol is based on the MakerDAO protocol, but with some differences. The stability mechanism is Algorithmic, and the collateral is exogenous. Users can deposit Link or wETH to mint DSC. The price feed is provided by Chainlink oracles and the app keep track of the active holders by using the subgraph from The Graph.

### How it works

Users can deposit Link or wETH to mint DSC. They can mint in DSC the USD worth of the collateral deposited. The collateralization ratio is 200%, meaning that the user can mint 50% of the collateral value. The user can also withdraw the collateral by burning the DSC minted.

The health factor is calculated by the following formula:

```
healthFactor = (totalCollateralWorthInUSD * Liquidation Treshold) / totalDscMinted
```

If the health factor is below 1, the user can be liquidated by others. The liquidation process is done by a liquidator, who must burn the DSC minted by the user and receive the collateral.

### Tests

You can run unit and fuzz tests by running the following command:

```
forge test
```

### Local deployment

You can deploy the contracts by running the following command:

```
make local
```

### Deployment

Take a look at the make file or read the Foundry documentation to deploy the contracts to the network. The documentation can be found [here](https://book.getfoundry.sh/forge/deploying).

### Addresses

- [DSCoin](https//sepolia.etherscan.io/address/0x9f3c6AfEe5b66D51Ea005EeA4591Ca65b4630Ef8): `0x9f3c6AfEe5b66D51Ea005EeA4591Ca65b4630Ef8`
- [DSCEngine](https://sepolia.etherscan.io/address/0x533EB9D0240A8F8f044581BE10E7487119d6307A):`0x533EB9D0240A8F8f044581BE10E7487119d6307A`
- [wETH](https://sepolia.etherscan.io/address/0xdd13E55209Fd76AfE204dBda4007C227904f0a81):`0xdd13E55209Fd76AfE204dBda4007C227904f0a81`
- [Link](https://sepolia.etherscan.io/address/0x779877A7B0D9E8603169DdbD7836e478b4624789): `0x779877A7B0D9E8603169DdbD7836e478b4624789`
- [wETH Price feed](https://sepolia.etherscan.io/address/0x694AA1769357215DE4FAC081bf1f309aDC325306): `0x694AA1769357215DE4FAC081bf1f309aDC325306`
- [Link Price feed](https://sepolia.etherscan.io/address/0xc59E3633BAAC79493d908e63626716e204A45EdF): `0xc59E3633BAAC79493d908e63626716e204A45EdF`
- [The graph](https://api.studio.thegraph.com/proxy/36860/stablecoin-protocol-graph/version/latest/graphql?query=%7B%0A++dscholders_collection+%7B%0A++++id%0A++++balance%0A++%7D%0A%7D)

### Links

The UI is under this [url](https://stablecoin-ui.onrender.com/) and the repository is [here](https://github.com/0fprod/stablecoin-ui)
