// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {DSCoin} from "../src/DSCoin.sol";
import {ConfigHelper} from "./ConfigHelper.s.sol";
import {ERC20Mock} from "@openzeppelin/mocks/token/ERC20Mock.sol";
import {AggregatorV3Mock} from "../test/mocks/AggregatorV3Mock.t.sol";

contract DeployEngine is Script {
// Run locally
// function run() external returns (DSCEngine, DSCoin) {
//     uint256 ANVIL_PRIVATE_KEY_1 = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
//     uint256 ANVIL_PRIVATE_KEY_2 = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
//     address deployer1 = vm.addr(ANVIL_PRIVATE_KEY_1);
//     address deployer2 = vm.addr(ANVIL_PRIVATE_KEY_2);

//     vm.startBroadcast(ANVIL_PRIVATE_KEY_1);

//     ERC20Mock wETHMock = new ERC20Mock();
//     ERC20Mock wBTCMock = new ERC20Mock();
//     AggregatorV3Mock wBTCPriceFeed = new AggregatorV3Mock(8, "wBTCPriceFeed", 14);
//     AggregatorV3Mock wETHPriceFeed = new AggregatorV3Mock(8, "wETHPriceFeed", 3000);

//     address wBTCaddress = address(wBTCMock);
//     address wETHaddress = address(wETHMock);
//     address wBTCPriceFeedAddress = address(wBTCPriceFeed);
//     address wETHPriceFeedAddress = address(wETHPriceFeed);

//     console2.log("wBTC address: %s", wBTCaddress);
//     console2.log("wETH address: %s", wETHaddress);
//     console2.log("wBTC price feed address: %s", wBTCPriceFeedAddress);
//     console2.log("wETH price feed address: %s", wETHPriceFeedAddress);

//     ERC20Mock(wETHaddress).mint(deployer1, 10 ether);
//     ERC20Mock(wBTCaddress).mint(deployer1, 150 ether);
//     ERC20Mock(wETHaddress).mint(deployer2, 8 ether);
//     ERC20Mock(wBTCaddress).mint(deployer2, 336 ether);

//     address[] memory tokenAddresses = new address[](2);
//     address[] memory priceFeedAddresses = new address[](2);
//     tokenAddresses[0] = wETHaddress;
//     tokenAddresses[1] = wBTCaddress;
//     priceFeedAddresses[0] = wETHPriceFeedAddress;
//     priceFeedAddresses[1] = wBTCPriceFeedAddress;

//     DSCoin dsc = new DSCoin(deployer1);
//     DSCEngine dscEngine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
//     dsc.transferOwnership(address(dscEngine));

//     // Approve and deposit collateral
//     ERC20Mock(wETHaddress).approve(address(dscEngine), 3 ether);
//     dscEngine.depositCollateral(wETHaddress, 3 ether);
//     ERC20Mock(wBTCaddress).approve(address(dscEngine), 5 ether);
//     dscEngine.depositCollateral(wBTCaddress, 5 ether);

//     vm.stopBroadcast();
//     vm.startBroadcast(ANVIL_PRIVATE_KEY_2);

//     ERC20Mock(wETHaddress).approve(address(dscEngine), 2 ether);
//     dscEngine.depositCollateral(wETHaddress, 2 ether);
//     ERC20Mock(wBTCaddress).approve(address(dscEngine), 4 ether);
//     dscEngine.depositCollateral(wBTCaddress, 4 ether);

//     vm.stopBroadcast();

//     return (dscEngine, dsc);
// }
}
