// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {DSCoin} from "../src/DSCoin.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

contract DSCoinTest is StdCheats, Test {
    DSCoin dsc;

    function setUp() public {
        dsc = new DSCoin();
    }

    function test_ShouldMintWhenCallerIsOwner() public {
        vm.prank(dsc.owner());
        bool minted = dsc.mint(address(this), 100);
        assertEq(dsc.balanceOf(address(this)), 100);
        assertEq(minted, true);
    }

    function test_ShouldFailWhenMintingFromNonOwner() public {
        vm.prank(address(0x1));
        vm.expectRevert();
        dsc.mint(address(0x2), 100);
    }

    function test_ShouldFailWhenMintingZero() public {
        vm.prank(dsc.owner());
        vm.expectRevert(withError("DSCoin__AmountMustBePositive()"));
        dsc.mint(address(this), 0);
    }

    function test_ShouldFailWhenMintingToZeroAddress() public {
        vm.prank(dsc.owner());
        vm.expectRevert(withError("DSCoin__CantMintToZeroAddress()"));
        dsc.mint(address(0), 100);
    }

    function test_ShouldBurnWhenCallerIsOwner() public {
        vm.prank(dsc.owner());
        dsc.mint(address(this), 100);
        dsc.burn(100);
        assertEq(dsc.balanceOf(address(this)), 0);
    }

    function test_ShouldFailWhenBurningFromNonOwner() public {
        vm.prank(address(0x1));
        vm.expectRevert();
        dsc.burn(100);
    }

    function test_ShouldFailWhenBurningZeroOrLess() public {
        vm.prank(dsc.owner());
        vm.expectRevert(withError("DSCoin__AmountMustBePositive()"));
        dsc.burn(0);
    }

    function test_ShouldFailWhenBurningMoreThanBalance() public {
        vm.prank(dsc.owner());
        dsc.mint(address(this), 100);
        vm.expectRevert(withError("DSCoin__BurnAmountExceedsBalance()"));
        dsc.burn(101);
    }

    function withError(
        string memory error
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSignature(error);
    }
}