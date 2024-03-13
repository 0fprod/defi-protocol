// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test, console2} from "forge-std/Test.sol";
import {DSCoin} from "../src/DSCoin.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

contract DSCoinTest is StdCheats, Test {
    DSCoin dsc;
    address owner = makeAddr("owner");

    function setUp() public {
        dsc = new DSCoin(owner);
    }

    function test_ShouldMintWhenCallerIsOwner() public {
        vm.prank(owner);
        bool minted = dsc.mint(owner, 100);
        assertEq(minted, true);
        assertEq(dsc.balanceOf(owner), 100);
    }

    function test_ShouldBurnWhenCallerIsOwner() public {
        vm.startPrank(owner);
        dsc.mint(owner, 100);
        dsc.burn(100);
        assertEq(dsc.balanceOf(owner), 0);
        vm.stopPrank();
    }

    function test_ShouldFail_WhenMintingFromNonOwner() public {
        vm.prank(address(0x1));
        vm.expectRevert();
        dsc.mint(address(0x1), 100);
    }

    function test_ShouldFail_WhenMintingZero() public {
        vm.prank(owner);
        vm.expectRevert(DSCoin.DSCoin__AmountMustBePositive.selector);
        dsc.mint(owner, 0);
    }

    function test_ShouldFail_WhenMintingToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(DSCoin.DSCoin__CantMintToZeroAddress.selector);
        dsc.mint(address(0), 100);
    }

    function test_ShouldFail_WhenBurningFromNonOwner() public {
        vm.prank(address(0x1));
        vm.expectRevert();
        dsc.burn(100);
    }

    function test_ShouldFail_WhenBurningZeroOrLess() public {
        vm.prank(owner);
        vm.expectRevert(DSCoin.DSCoin__AmountMustBePositive.selector);
        dsc.burn(0);
    }

    function test_ShouldFail_WhenBurningMoreThanBalance() public {
        vm.startPrank(owner);
        dsc.mint(owner, 100);
        vm.expectRevert(DSCoin.DSCoin__BurnAmountExceedsBalance.selector);
        dsc.burn(101);
        vm.stopPrank();
    }
}
