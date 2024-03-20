// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Mock} from "../mocks/AggregatorV3Mock.t.sol";
import {Test, StdInvariant, console} from "forge-std/Test.sol";
import {DSCoin} from "../../src/DSCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {ConfigHelper} from "../../script/ConfigHelper.s.sol";
import {DSCProtocolHandler} from "./DSCProtocol.handler.t.sol";

contract DSCEngineInvariants is StdInvariant, Test {
    DSCoin dsc;
    DSCEngine engine;
    DSCProtocolHandler handler;
    ConfigHelper.Configuration config;
    address wETH;
    address wBTC;
    address alice = makeAddr("alice");

    function setUp() external {
      address owner = makeAddr("owner");
      ConfigHelper helperConfig = new ConfigHelper(); 
      config = helperConfig.getTokensAndPriceFeeds();
      address[] memory tokens = new address[](2);
      tokens[0] = config.wETHaddress;
      tokens[1] = config.wBTCaddress;
      address[] memory priceFeeds = new address[](2);
      priceFeeds[0] = config.wETHPriceFeedAddress;
      priceFeeds[1] = config.wBTCPriceFeedAddress;
      wETH = config.wETHaddress;
      wBTC = config.wBTCaddress;
      
      dsc = new DSCoin(owner);
      engine = new DSCEngine(tokens, priceFeeds, address(dsc));
      handler = new DSCProtocolHandler(address(dsc), address(engine), config, alice);
      targetContract(address(handler));
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
      uint totalSupply = dsc.totalSupply();
      uint wETHDeposited = IERC20(wETH).balanceOf(address(engine));
      uint wBTCDeposited = IERC20(wBTC).balanceOf(address(engine));

      uint wETHValue = engine.getUSDValue(config.wETHPriceFeedAddress, wETHDeposited);
      uint wBTCValue = engine.getUSDValue(config.wBTCPriceFeedAddress, wBTCDeposited);

      assert(wETHValue + wBTCValue >= totalSupply);
    }
}

// Apodos para
// Victor -> 
// Lucas
// Luciano
// Nicolas
