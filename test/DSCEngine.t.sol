// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {ERC20Mock} from "@openzeppelin/mocks/token/ERC20Mock.sol";
import {AggregatorV3Mock} from "./mocks/AggregatorV3Mock.t.sol";
import {DSCoin} from "../src/DSCoin.sol";

contract DSCEngineTest is StdCheats, Test {
    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);

    AggregatorV3Mock wBTCPriceFeed = new AggregatorV3Mock(8, "wBTCPriceFeed");
    AggregatorV3Mock wETHPriceFeed = new AggregatorV3Mock(8, "wETHPriceFeed");
    DSCoin dsc;
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
    uint256 aHundredEther = 100 ether;
    uint256 constant PRICE_FEED_DECIMALS = 10e8;

    function setUp() public {
        address[] memory collateralTokens = new address[](2);
        collateralTokens[0] = wETHaddress;
        collateralTokens[1] = wBTCaddress;

        address[] memory priceFeeds = new address[](2);
        priceFeeds[0] = address(wETHPriceFeed);
        priceFeeds[1] = address(wBTCPriceFeed);

        dsc = new DSCoin(owner);
        engine = new DSCEngine(collateralTokens, priceFeeds, address(dsc));

        vm.prank(owner);
        dsc.transferOwnership(address(engine));

        wETHMock.mint(alice, aHundredEther);
        wBTCMock.mint(bob, aHundredEther);
    }

    function test_AllowsDepositingCollateral() public {
        // Arrange
        vm.startPrank(alice);
        wETHMock.approve(address(engine), aHundredEther);
        vm.expectEmit(
            shouldVerifyFirstIndexedParameter,
            shouldVerifySecondIndexedParameter,
            shouldVerifyThirdIndexedParameter,
            !shouldVerifyData
        );

        // Act
        emit CollateralDeposited(alice, wETHaddress, 100); // this is the event we expect to be emitted in the next line
        engine.depositCollateral(wETHaddress, aHundredEther);

        // Assert
        vm.stopPrank();
        assertEq(engine.getCollateral(alice, wETHaddress), aHundredEther);
    }

    function test_RevertsWhen_DepositingWithoutAllowance() public {
        vm.prank(alice);

        vm.expectRevert();
        engine.depositCollateral(wETHaddress, 100);
    }

    function test_RevertsWhen_DepositingZeroCollateral() public {
        vm.prank(alice);

        vm.expectRevert(DSCEngine.DSCEngine__AmountMustBePositive.selector);
        engine.depositCollateral(wETHaddress, 0);
    }

    function test_RevertsWhen_DepositingInvalidToken() public {
        vm.startPrank(alice);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressMustBeValid.selector);
        engine.depositCollateral(makeAddr("invalid"), 100);

        vm.stopPrank();
    }

    function test_RevertsWhen_MintingZeroDSC() public {
        vm.startPrank(alice);

        vm.expectRevert(DSCEngine.DSCEngine__AmountMustBePositive.selector);
        engine.mintDSC(0);

        vm.stopPrank();
    }

    function test_AllowUsersToMintDSCTokensWithEnoughCollateral() public {
        // Arrange
        vm.startPrank(alice);
        wETHMock.approve(address(engine), aHundredEther);
        engine.depositCollateral(wETHaddress, aHundredEther);

        // Act
        wETHPriceFeed.updateRoundData(100); // returns 100 * 10e8
        uint256 dscAmount = 1 ether;
        engine.mintDSC(dscAmount);

        // Assert
        assertEq(engine.getCollateral(alice, wETHaddress), aHundredEther);
        assertEq(DSCoin(engine.getStablecoin()).balanceOf(alice), dscAmount);
        vm.stopPrank();
    }

    function test_RevertsWhen_UsersMintDSCWithoutEnoughCollateral() public {
        // Arrange
        vm.startPrank(alice);
        wETHPriceFeed.updateRoundData(100); // returns 100 * 10e8

        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__InsufficientCollateral.selector, 0));
        engine.mintDSC(1 ether);

        vm.stopPrank();
    }

    function test_AllowsUsersBurnDSC() public {
        // Arrange
        vm.startPrank(alice);
        wETHMock.approve(address(engine), aHundredEther);
        engine.depositCollateral(wETHaddress, aHundredEther);
        wETHPriceFeed.updateRoundData(100); // returns 100 * 10e8
        engine.mintDSC(1 ether);

        // Act
        DSCoin(engine.getStablecoin()).approve(address(engine), 1 ether);
        engine.burnDSC(1 ether);

        // Assert
        assertEq(engine.getCollateral(alice, wETHaddress), aHundredEther);
        assertEq(DSCoin(engine.getStablecoin()).balanceOf(alice), 0);
        vm.stopPrank();
    }

    function test_AllowsUsersToRedeeemCollateralIfTheHealthFactorIsHealthyEnough() public {
        // Arrange
        vm.startPrank(alice);
        wETHMock.approve(address(engine), 2.5 ether);
        engine.depositCollateral(wETHaddress, 2.5 ether);
        wETHPriceFeed.updateRoundData(1);
        engine.mintDSC(1 ether);

        // Act
        engine.redeemCollateral(wETHaddress, 0.5 ether);

        // // Assert
        assertEq(engine.getCollateral(alice, wETHaddress), 2 ether);
        assertEq(DSCoin(engine.getStablecoin()).balanceOf(alice), 1 ether);
        vm.stopPrank();
    }

    function test_RevertsWhen_UsersRedeemCollateralIfTheHealthFactorIsNotHealthyEnough() public {
        // Arrange
        uint256 expectedHealthFactor = 0.5 ether;
        vm.startPrank(alice);
        wETHMock.approve(address(engine), 1 ether);
        engine.depositCollateral(wETHaddress, 1 ether);
        wETHPriceFeed.updateRoundData(1);
        engine.mintDSC(0.5 ether);

        // Act
        vm.expectRevert(
            abi.encodeWithSelector(DSCEngine.DSCEngine__InsufficientCollateral.selector, expectedHealthFactor)
        );
        engine.redeemCollateral(wETHaddress, 0.5 ether);

        vm.stopPrank();
    }

    function test_AllowUsersToViewTheirHealthFactor() public {
        // Arrange
        vm.startPrank(alice);
        wETHMock.approve(address(engine), 2 ether);
        wETHPriceFeed.updateRoundData(1);
        engine.depositCollateral(wETHaddress, 2 ether);
        engine.mintDSC(1 ether);

        // Act
        uint256 healthFactor = engine.getHealthFactor(alice);

        // Assert
        assertEq(healthFactor, 1 ether);
        vm.stopPrank();
    }

    function test_AllowsBobToLiquidateAlice() public {
        // Arrange
        vm.startPrank(alice);
        wETHMock.approve(address(engine), 2 ether);
        engine.depositCollateral(wETHaddress, 2 ether);
        wETHPriceFeed.updateRoundData(5);
        engine.mintDSC(5 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        wBTCMock.approve(address(engine), 2 ether);
        engine.depositCollateral(wBTCaddress, 2 ether);
        wBTCPriceFeed.updateRoundData(10);
        engine.mintDSC(10 ether);

        // Act
        uint256 bobDscToBurn = 1 ether;
        wETHPriceFeed.updateRoundData(4);
        DSCoin(engine.getStablecoin()).approve(address(engine), 1 ether);
        engine.liquidate(alice, wETHaddress, bobDscToBurn);

        // Assert
        assertEq(engine.getCollateral(bob, wETHaddress), 2 ether);
        assertEq(DSCoin(engine.getStablecoin()).balanceOf(bob), 9 ether);
        assertEq(engine.getCollateral(alice, wETHaddress), 0);
        assertEq(DSCoin(engine.getStablecoin()).balanceOf(alice), 5 ether);
        vm.stopPrank();
    }

    function test_RevertsWhen_BobTriesToLiquidateHealthyUsers() public {
        // Arrange
        vm.startPrank(alice);
        wETHMock.approve(address(engine), 2 ether);
        engine.depositCollateral(wETHaddress, 2 ether);
        wETHPriceFeed.updateRoundData(5);
        engine.mintDSC(5 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        wBTCMock.approve(address(engine), 2 ether);
        engine.depositCollateral(wBTCaddress, 2 ether);
        wBTCPriceFeed.updateRoundData(10);
        engine.mintDSC(10 ether);

        // Act
        vm.expectRevert(DSCEngine.DSCEngine__HealthFactorOk.selector);
        engine.liquidate(alice, wETHaddress, 1 ether);

        vm.stopPrank();
    }

    function test_AllowUsersToQueryTheMaximumMintableDsc_WhenTheyHaveNoDeposits() public {
        // Arrange
        vm.startPrank(alice);
        uint256 collateralAmount = 2 ether;
        wETHPriceFeed.updateRoundData(1);

        // Act
        uint256 maxMintableDsc = engine.getMaxMintableDsc(wETHaddress, collateralAmount);

        // Assert
        assertEq(maxMintableDsc, 1 ether);
        vm.stopPrank();
    }

    function test_AllowUsersToQueryTheMaximumMintableDsc_WhenTheyHaveCollateral() public {
        // Arrange
        vm.startPrank(alice);
        wETHMock.approve(address(engine), 2 ether);
        engine.depositCollateral(wETHaddress, 2 ether);
        uint256 collateralAmount = 2 ether;
        wETHPriceFeed.updateRoundData(1);

        // Act
        uint256 maxMintableDsc = engine.getMaxMintableDsc(wETHaddress, collateralAmount);

        // Assert
        assertEq(maxMintableDsc, 2 ether);
        vm.stopPrank();
    }

    function test_AllowUsersToQueryTheMaximumMintableDsc_WhenTheyHaveCollateralAndDscMinted() public {
        // Arrange
        vm.startPrank(alice);
        wETHMock.approve(address(engine), 2 ether);
        engine.depositCollateral(wETHaddress, 2 ether);
        uint256 collateralAmount = 2 ether;
        wETHPriceFeed.updateRoundData(1);
        engine.mintDSC(1 ether);

        // Act
        uint256 maxMintableDsc = engine.getMaxMintableDsc(wETHaddress, collateralAmount);

        // Assert
        assertEq(maxMintableDsc, 1 ether);
        vm.stopPrank();
    }

    function test_AllowUsersToQueryTheMaximumMintableDsc_WhenTheirCollateralIs0Usd() public {
        // Arrange
        vm.startPrank(alice);
        uint256 collateralAmount = 2 ether;
        wETHPriceFeed.updateRoundData(0);

        // Act
        uint256 maxMintableDsc = engine.getMaxMintableDsc(wETHaddress, collateralAmount);

        // Assert
        assertEq(maxMintableDsc, 0 ether);
        vm.stopPrank();
    }

    function test_AllowUsersToDepositCollateralAndMintDsc() public {
        // Arrange
        vm.startPrank(alice);
        wETHMock.approve(address(engine), 2 ether);
        wETHPriceFeed.updateRoundData(1);

        // Act
        engine.depositCollateralAndMintDsc(wETHaddress, 2 ether, 1 ether);

        // Assert
        assertEq(engine.getCollateral(alice, wETHaddress), 2 ether);
        assertEq(DSCoin(engine.getStablecoin()).balanceOf(alice), 1 ether);
        vm.stopPrank();
    }

    function test_AllowUsersToRedeemCollateralAndBurnDsc() public {
        // Arrange
        vm.startPrank(alice);
        wETHMock.approve(address(engine), 2 ether);
        dsc.approve(address(engine), 1 ether);
        wETHPriceFeed.updateRoundData(1);
        engine.depositCollateralAndMintDsc(wETHaddress, 2 ether, 1 ether);

        // Act
        engine.redeemCollateralAndBurnDsc(wETHaddress, 1 ether, 0.5 ether);

        // Assert
        assertEq(engine.getCollateral(alice, wETHaddress), 1 ether);
        assertEq(DSCoin(engine.getStablecoin()).balanceOf(alice), 0.5 ether);
        vm.stopPrank();
    }
}
