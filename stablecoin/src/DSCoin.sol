// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @title DecentralizedStableCoin (DSCoin)
 * @author Fran Palacios
 * Collateral: Exogenous
 * Minting (Stability Mechanism): Decentralized (Algorithmic)
 * Value (Relative Stability): Anchored (Pegged to USD)
 * Collateral Type: Crypto
 *
 * This is the contract meant to be owned by DSCEngine.
 * It is a ERC20 token that can be minted and burned by the DSCEngine smart contract.
 */
contract DSCoin is ERC20, ERC20Burnable, Ownable {
    error DSCoin__AmountMustBePositive();
    error DSCoin__CantMintToZeroAddress();
    error DSCoin__BurnAmountExceedsBalance();

    constructor() ERC20("DSCoin", "DSC") Ownable(msg.sender) {}

    function mint(address to, uint256 amount) external onlyOwner returns (bool) {
        if (amount <= 0) revert DSCoin__AmountMustBePositive();
        if (to == address(0)) revert DSCoin__CantMintToZeroAddress();
        _mint(to, amount);
        return true;
    }

    function burn(uint256 amount) public override onlyOwner {
        if (amount <= 0) revert DSCoin__AmountMustBePositive();
        if (amount > balanceOf(msg.sender)) {
            revert DSCoin__BurnAmountExceedsBalance();
        }
        _burn(msg.sender, amount);
    }
}
