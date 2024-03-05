// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {DSCoin} from "../src/DSCoin.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {TestUtilities} from "./Utility.t.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {ERC20Mock} from "@openzeppelin/mocks/token/ERC20Mock.sol";

contract DSCEngineTest is StdCheats, Test {
    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);

    DSCEngine engine;
    ERC20Mock wETHMock = new ERC20Mock();
    ERC20Mock wBTCMock = new ERC20Mock();
    address wETHaddress = address(wETHMock);
    address wBTCaddress = address(wBTCMock);
    address owner = makeAddr("owner");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    bool shouldVerifyFirstIndexedParameter = true;
    bool shouldVerifySecondIndexedParameter = true;
    bool shouldVerifyThirdIndexedParameter = true;
    bool shouldVerifyData = true;

    function setUp() public {
        address[] memory collateralTokens = new address[](2);
        collateralTokens[0] = wETHaddress;
        collateralTokens[1] = wBTCaddress;
        dsc = new DSCEngine(collateralTokens);

        wETHMock.mint(alice, 100 ether);
    }

    // people can deposit collateral and mint dsc
    // people can redeem collateral for dsc
    // people can burn dsc to get back collateral
    // people can liquidate other people's collateral if it falls below a certain ratio
    // health retrieves how healthy the people's collateral is

    function test_AllowsDepositingCollateral() public {
        // Arrange
        vm.startPrank(alice);
        uint256 amount = 100;
        wETHMock.approve(address(engine), amount);

        // Act
        vm.expectEmit(
            shouldVerifyFirstIndexedParameter,
            shouldVerifySecondIndexedParameter,
            shouldVerifyThirdIndexedParameter,
            !shouldVerifyData
        );
        // The event we expect
        emit CollateralDeposited(alice, wETHaddress, 100);

        engine.depositCollateral(wETHaddress, amount);
        vm.stopPrank();

        // Assert
        assertEq(engine.getCollateral(alice, wETHaddress), amount);
    }

    function test_RevertsWhen_DepositingWithoutAllowance() public {
        vm.startPrank(alice);
        uint256 amount = 100;
        vm.expectRevert();
        engine.depositCollateral(wETHaddress, amount);
        vm.stopPrank();
    }

    function test_RevertsWhen_DepositingZeroCollateral() public {
        vm.startPrank(alice);
        uint256 amount = 0;
        wETHMock.approve(address(engine), amount);
        vm.expectRevert(DSCEngine.DSCEngine__AmountMustBePositive.selector);
        engine.depositCollateral(wETHaddress, amount);
        vm.stopPrank();
    }

    function test_RevertsWhen_DepositingInvalidToken() public {
        vm.startPrank(alice);
        uint256 amount = 100;
        wETHMock.approve(address(engine), amount);
        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressMustBeValid.selector);
        engine.depositCollateral(makeAddr("invalid"), amount);
        vm.stopPrank();
    }
        vm.stopPrank();
    }
}
