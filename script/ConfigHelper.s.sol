// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

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

    bool isDevelopment = true;
    uint16 constant ANVIL_CHAINID = 31337;
    uint8 constant PRICE_FEED_DECIMALS = 8;
    int constant wETHPrice = 2000;
    int constant wBTCPrice = 40000;

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
    
    function _assignDevelopmentTokensAndPriceFeeds(Configuration memory config) internal  {
        AggregatorV3Mock wBTCPriceFeed = new AggregatorV3Mock(PRICE_FEED_DECIMALS, "wBTCPriceFeed", wBTCPrice);
        AggregatorV3Mock wETHPriceFeed = new AggregatorV3Mock(PRICE_FEED_DECIMALS, "wETHPriceFeed", wETHPrice);
        ERC20Mock wETHMock = new ERC20Mock();
        ERC20Mock wBTCMock = new ERC20Mock();

        config.wBTCaddress = address(wBTCMock);
        config.wETHaddress = address(wETHMock);
        config.wBTCPriceFeedAddress = address(wBTCPriceFeed);
        config.wETHPriceFeedAddress = address(wETHPriceFeed);
    }
    
    function _assignProductionTokensAndPriceFeeds(Configuration memory config) internal {
        // Assign production tokens and price feeds here
    }
}
