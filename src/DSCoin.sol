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
    error DSCoin__CannotBurnFromContract();

    uint256 public circulatingSupply;
    uint256 public totalHolders;

    constructor(address owner) ERC20("DSCoin", "DSC") Ownable(owner) {}

    function mint(address to, uint256 amount) external virtual onlyOwner returns (bool) {
        if (amount <= 0) revert DSCoin__AmountMustBePositive();
        if (to == address(0)) revert DSCoin__CantMintToZeroAddress();
        if (balanceOf(to) == 0) {
            totalHolders += 1;
        }
        _mint(to, amount);
        circulatingSupply += amount;
        _approve(to, owner(), allowance(to, owner()) + amount);
        return true;
    }

    function burn(address from, uint256 amount) public onlyOwner {
        if (amount <= 0) revert DSCoin__AmountMustBePositive();
        if (amount > balanceOf(msg.sender)) {
            revert DSCoin__BurnAmountExceedsBalance();
        }
        _burn(msg.sender, amount);
        circulatingSupply -= amount;
        if (balanceOf(from) == 0) {
            totalHolders -= 1;
        }
    }

    function burn(uint256 __) public view override onlyOwner {
        revert DSCoin__CannotBurnFromContract();
    }
}
