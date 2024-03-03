// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TestUtilities {
    function withError(string memory error) public pure returns (bytes memory) {
        return abi.encodeWithSignature(error);
    }

    function approve(address token, address spender, uint256 amount) public {
        IERC20(token).approve(spender, amount);
    }
}
