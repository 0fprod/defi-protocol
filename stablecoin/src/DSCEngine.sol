// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {DSCoin} from "./DSCoin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import console.log
import {console} from "forge-std/Console.sol";

/**
 * @title DSCEngine
 * @author Fran Palacios
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg at all times.
 * This is a stablecoin with the properties:
 * - Exogenously Collateralized
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * It is similar to DAI if DAI had no governance, no fees, and was backed by only WETH and WBTC.
 *
 * Our DSC system should always be "overcollateralized". At no point, should the value of
 * all collateral < the $ backed value of all the DSC.
 *
 * @notice This contract is the core of the Decentralized Stablecoin system. It handles all the logic
 * for minting and redeeming DSC, as well as depositing and withdrawing collateral.
 * @notice This contract is based on the MakerDAO DSS system
 */
contract DSCEngine {
    // Errors
    error DSCEngine__AmountMustBePositive();
    error DSCEngine__TokenAddressMustBeValid();
    error DSCEngine__TransferFailed();

    // The DSC token
    DSCoin public dsc;

    // The collateral tokens
    address private immutable i_wETH;
    address private immutable i_wBTC;
    address private immutable i_dsCoin;

    mapping(address user => mapping(address token => uint256 amount)) private s_usersCollateral;

    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);

    constructor(address[] memory _collateralTokens) {
        dsc = new DSCoin();
        i_wETH = _collateralTokens[0];
        i_wBTC = _collateralTokens[1];
    }

    modifier validToken(address _token) {
        if (_token != i_wETH && _token != i_wBTC) {
            revert DSCEngine__TokenAddressMustBeValid();
        }
        _;
    }

    /**
     * @dev Deposits collateral tokens into the contract.
     * @param _token The address of the collateral token.
     * @param _amount The amount of collateral tokens to deposit.
     * @notice Follows Checks-Effects-Interactions pattern.
     * @notice The `_amount` must be a positive value.
     * @notice The caller must have approved the contract to spend `_amount` of their collateral tokens.
     * @notice Reverts with `DSCEngine__AmountMustBePositive` if `_amount` is less than or equal to zero.
     * @notice Reverts with `DSCEngine__DepositFailed` if the transfer of collateral tokens fails.
     */
    function depositCollateral(address _token, uint256 _amount) public validToken(_token) {
        if (_amount <= 0) {
            revert DSCEngine__AmountMustBePositive();
        }

        IERC20 token = IERC20(_token);
        bool success = token.transferFrom(msg.sender, address(this), _amount);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
        s_usersCollateral[msg.sender][_token] += _amount;
        emit CollateralDeposited(msg.sender, _token, _amount);
    }

    // create a public view function that queries s_usersCollateral
    function getCollateral(address _user, address _token) public view returns (uint256) {
        return s_usersCollateral[_user][_token];
    }
}
