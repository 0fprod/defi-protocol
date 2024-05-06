// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {ERC20Mock} from "@openzeppelin/mocks/token/ERC20Mock.sol";
import {AggregatorV3Mock} from "../test/mocks/AggregatorV3Mock.t.sol";

contract ConfigHelper is Script {
    struct Configuration {
        address wBTCaddress;
        address wETHaddress;
        address wBTCPriceFeedAddress;
        address wETHPriceFeedAddress;
    }

    bool public isDevelopment = true;
    uint16 constant ANVIL_CHAINID = 31337;
    uint8 constant PRICE_FEED_DECIMALS = 8;
    int256 constant wETHPrice = 3876;
    int256 constant wBTCPrice = 14;
    uint256 public ANVIL_PRIVATE_KEY_1 = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public ANVIL_PRIVATE_KEY_2 = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

    constructor() {
        if (block.chainid == ANVIL_CHAINID) {
            isDevelopment = true;
        } else {
            isDevelopment = false;
        }
    }

    function getTokensAndPriceFeeds() public returns (Configuration memory) {
        Configuration memory config;

        if (isDevelopment) {
            _assignDevelopmentTokensAndPriceFeeds(config);
        } else {
            _assignProductionTokensAndPriceFeeds(config);
        }

        return config;
    }

    function _assignDevelopmentTokensAndPriceFeeds(Configuration memory config) internal {
        AggregatorV3Mock wBTCPriceFeed = new AggregatorV3Mock(PRICE_FEED_DECIMALS, "wBTCPriceFeed", wBTCPrice);
        AggregatorV3Mock wETHPriceFeed = new AggregatorV3Mock(PRICE_FEED_DECIMALS, "wETHPriceFeed", wETHPrice);
        ERC20Mock wETHMock = new ERC20Mock();
        ERC20Mock wBTCMock = new ERC20Mock();

        config.wBTCaddress = address(wBTCMock);
        config.wETHaddress = address(wETHMock);
        config.wBTCPriceFeedAddress = address(wBTCPriceFeed);
        config.wETHPriceFeedAddress = address(wETHPriceFeed);
    }

    function _assignProductionTokensAndPriceFeeds(Configuration memory config) internal pure {
        // Assign production tokens and price feeds here
        // Link Token 0x779877A7B0D9E8603169DdbD7836e478b4624789
        // LINK/USD 0xc59E3633BAAC79493d908e63626716e204A45EdF
        // 8 decimals

        // wETH token 0xdd13E55209Fd76AfE204dBda4007C227904f0a81
        // ETH/USD 0x694AA1769357215DE4FAC081bf1f309aDC325306
        // 8 decimals
        config.wBTCaddress = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
        config.wETHaddress = 0xdd13E55209Fd76AfE204dBda4007C227904f0a81;
        config.wBTCPriceFeedAddress = 0xc59E3633BAAC79493d908e63626716e204A45EdF;
        config.wETHPriceFeedAddress = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    }
}
