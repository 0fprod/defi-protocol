// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {DSCoin} from "./DSCoin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/interfaces/AggregatorV3Interface.sol";
import {console, console2} from "forge-std/Test.sol";

/**
 * @title DSCEngine
 * @author Fran Palacios (following Patrick Collins)
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

contract DSCEngine is ReentrancyGuard {
    ////////////////
    // Errors     //
    ////////////////
    error DSCEngine__AmountMustBePositive();
    error DSCEngine__TokenAddressMustBeValid();
    error DSCEngine__TransferFailed();
    error DSCEngine__InsufficientCollateral(uint256 healthFactor);
    error DSCEngine__MintingFailed();
    error DSCEngine__HealthFactorOk();

    /////////////////////////
    // Immutable variables //
    /////////////////////////
    uint8 private constant LIQUIDATION_THRESHOLD = 50; // 50% so 2x overcollateralized
    uint8 private constant LIQUIDATION_PRECISION = 100;
    uint private constant MININUM_HEALTH_FACTOR = 1e18;
    uint private constant ADDITIONAL_FEED_PRECISION = 1e10; // This is to adjust all the priced to 18 decimals (in terms of wei). Most of the price feeds aginst USD have 8 decimals.
    uint private constant PRECISION = 1e18;
    address private immutable i_wETH;
    address private immutable i_wBTC;
    address private immutable i_wETHPriceFeed;
    address private immutable i_wBTCPriceFeed;
    DSCoin private immutable i_dsc;

    /////////////////////
    // State variables //
    /////////////////////
    mapping(address user => mapping(address token => uint256 amount)) private s_usersCollateral;
    mapping(address user => uint256 amount) private s_usersDSC;
    mapping(address token => address priceFeed) private s_priceFeeds;

    ////////////////
    // Events     //
    ////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);
    event CollateralRedeemed(address indexed user, address indexed token, uint256 amount);

    constructor(address[] memory _collateralTokens, address[] memory _priceFeeds, address _dsc) {
        i_dsc = DSCoin(_dsc);
        i_wETH = _collateralTokens[0];
        i_wBTC = _collateralTokens[1];
        i_wETHPriceFeed = _priceFeeds[0];
        i_wBTCPriceFeed = _priceFeeds[1];
        s_priceFeeds[i_wETH] = i_wETHPriceFeed;
        s_priceFeeds[i_wBTC] = i_wBTCPriceFeed;
    }

    ////////////////
    // Modifiers  //
    ////////////////
    modifier validToken(address _token) {
        if (_token != i_wETH && _token != i_wBTC) {
            revert DSCEngine__TokenAddressMustBeValid();
        }
        _;
    }

    modifier positiveAmount(uint256 _amount) {
        if (_amount <= 0) {
            revert DSCEngine__AmountMustBePositive();
        }
        _;
    }

    ///////////////////////////
    // External functions    //
    ///////////////////////////

    
    /**
     * @dev Deposits collateral and mints DSC tokens.
     * @param _token The address of the collateral token.
     * @param _collateralAmount The amount of collateral to deposit.
     * @param _dscAmount The amount of DSC tokens to mint.
     */
    function depositCollateralAndMintDsc(address _token, uint256 _collateralAmount, uint256 _dscAmount) external {
        depositCollateral(_token, _collateralAmount);
        mintDSC(_dscAmount);
    }

    /**
     * @dev Redeems collateral and burns DSC tokens.
     * @param _token The address of the collateral token.
     * @param _collateralAmount The amount of collateral tokens to redeem.
     * @param _dscAmount The amount of DSC tokens to burn.
     */
    function redeemCollateralAndBurnDsc(address _token, uint256 _collateralAmount, uint256 _dscAmount) external {
        burnDSC(_dscAmount);
        redeemCollateral(_token, _collateralAmount);
    }

    ///////////////////////////
    // Public functions     //
    ///////////////////////////
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
    function depositCollateral(address _token, uint256 _amount)
        public
        validToken(_token)
        positiveAmount(_amount)
        nonReentrant
    {
        IERC20 token = IERC20(_token);
        bool success = token.transferFrom(msg.sender, address(this), _amount);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
        s_usersCollateral[msg.sender][_token] += _amount;
        emit CollateralDeposited(msg.sender, _token, _amount);
    }

    /**
     * @dev Mints DSC tokens for the caller.
     * @param _amount The amount of DSC tokens to mint.
     * @notice Follows Checks-Effects-Interactions pattern.
     * @notice The `_amount` must be a positive value.
     * @notice Reverts with `DSCEngine__AmountMustBePositive` if `_amount` is less than or equal to zero.
     * @notice Reverts with `DSCEngine__InsufficientCollateral` if the caller does not have enough collateral to mint the `_amount` of DSC tokens.
     */
    function mintDSC(uint256 _amount) public positiveAmount(_amount) nonReentrant {
        s_usersDSC[msg.sender] += _amount;
        _revertIfInsufficientCollateral(msg.sender);
        bool minted = i_dsc.mint(msg.sender, _amount);
        if (!minted) {
            revert DSCEngine__MintingFailed();
        }
    }

    /**
     * @dev Burns a specified amount of DSC tokens from the caller's balance.
     * @param _amount The amount of DSC tokens to burn.
     * @notice This function is used to burn DSC tokens from the caller's balance. The caller must have sufficient DSC tokens in their balance to burn. The function transfers the specified amount of DSC tokens from the caller to the contract, and then burns them by calling the `burn` function of the `i_dsc` token contract.
     * @notice This function is non-reentrant and requires a positive amount of DSC tokens to be burned.
     * @notice If the transfer of DSC tokens from the caller to the contract fails, the function reverts with a `DSCEngine__TransferFailed` error.
     */
    function burnDSC(uint256 _amount) public positiveAmount(_amount) nonReentrant {
        s_usersDSC[msg.sender] -= _amount;
        bool s = i_dsc.transferFrom(msg.sender, address(this), _amount);
        if (!s) {
            revert DSCEngine__TransferFailed();
        }
        i_dsc.burn(_amount);
    }

    /**
     * @dev Allows a user to redeem a specified amount of collateral.
     * @param _collateral The address of the collateral token.
     * @param _amount The amount of collateral to redeem.
     */
    function redeemCollateral(address _collateral, uint _amount) public {
        s_usersCollateral[msg.sender][_collateral] -= _amount;
        bool s = IERC20(_collateral).transfer(msg.sender, _amount);
        if (!s) {
            revert DSCEngine__TransferFailed();
        }
        _revertIfInsufficientCollateral(msg.sender);
        emit CollateralRedeemed(msg.sender, _collateral, _amount);
    }

    /**
     * @dev Liquidates the insolvent user by transferring their collateral to the caller and burning a specified amount of DSC tokens.
     * @param _insolvetUser The address of the insolvent user.
     * @param _collateralAddress The address of the collateral token.
     * @param _dscToBurn The amount of DSC tokens to burn.
     * @notice reverst with DSCEngine__HealthFactorOk if the insolvent user is not liquidatable.
     * @notice reverst with DSCEngine__TransferFailed if the transfer of collateral tokens fails.
     */
    function liquidate(address _insolvetUser, address _collateralAddress, uint _dscToBurn) public {
        if (!_isLiquidatable(_insolvetUser)) {
            revert DSCEngine__HealthFactorOk();
        }

        uint insolvetsUsersCollateral = s_usersCollateral[_insolvetUser][_collateralAddress];
        s_usersCollateral[_insolvetUser][_collateralAddress] = 0;
        s_usersCollateral[msg.sender][_collateralAddress] += insolvetsUsersCollateral;
        bool s = IERC20(_collateralAddress).transfer(msg.sender, insolvetsUsersCollateral);
        
        if (!s) {
            revert DSCEngine__TransferFailed();
        }
        burnDSC(_dscToBurn);
    }
    //////////////////////////////////////////
    // Private and Internal view functions  //
    //////////////////////////////////////////
    function _isLiquidatable(address _user) private view returns (bool) {
        return _healthFactor(_user) < MININUM_HEALTH_FACTOR;
    }

    /**
     * @dev Checks the health factor of the user to determine if they have enough collateral.
     * If the health factor is below the required threshold, the function will revert.
     */
    function _revertIfInsufficientCollateral(address _user) private view {
        uint256 usersHealthFactor = _healthFactor(_user);
        if (usersHealthFactor < MININUM_HEALTH_FACTOR) {
            revert DSCEngine__InsufficientCollateral(usersHealthFactor);
        }
    }

    /**
     * @dev Returns how close the liquidation is for a user.
     * If the users goes below a certain health factor, they can be liquidated.
     * @param _user The address of the user.
     * @return The health factor of the user.
     */
    function _healthFactor(address _user) private view returns (uint256) {
        (uint256 totalDscMinted, uint256 totalCollateralInUsd) = _getAccountInformation(_user);
        if (totalDscMinted == 0) return type(uint256).max;
        uint256 collateralAdjustmentForThreshold = (totalCollateralInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;

        return (collateralAdjustmentForThreshold * PRECISION) / totalDscMinted;
    }

    /**
     * @dev Retrieves the account information for a given user.
     * @param _user The address of the user.
     * @return totalUsdMinted The total amount of USD minted by the user.
     * @return totalCollateralInUsd The total collateral value in USD for the user.
     */
    function _getAccountInformation(address _user) private view returns (uint256, uint256) {
        uint256 totalUsdMinted = s_usersDSC[_user];
        uint256 totalCollateralInUsd = getCollateralUSDValue(_user);
        return (totalUsdMinted, totalCollateralInUsd);
    }

    ////////////////////////////
    // Public view functions //
    ///////////////////////////
    function getCollateral(address _user, address _token) public view returns (uint256) {
        return s_usersCollateral[_user][_token];
    }

    function getStablecoin() public view returns (address) {
        return address(i_dsc);
    }

    function getHealthFactor(address _user) public view returns (uint256) {
        return _healthFactor(_user);
    }

    /**
     * @dev Retrieves the total USD value of the collateral held by a specific user.
     * @param user The address of the user.
     * @return The total USD value of the user's collateral.
     */
    function getCollateralUSDValue(address user) public view returns (uint256) {
        uint256 wETHamount = s_usersCollateral[user][i_wETH];
        uint256 wBTCamount = s_usersCollateral[user][i_wBTC];
        uint256 wETHValue = getUSDValue(i_wETHPriceFeed, wETHamount);
        uint256 wBTCValue = getUSDValue(i_wBTCPriceFeed, wBTCamount);

        return wETHValue + wBTCValue;
    }

    /**
     * @dev Returns the USD value of a given token amount.
     * @param _priceFeedAddress The address of the Chainlink price feed.
     * @param _amount The amount of tokens.
     * @return The USD value of the token amount.
     */
    function getUSDValue(address _priceFeedAddress, uint256 _amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeedAddress);
        (, int256 price,,,) = priceFeed.latestRoundData();

        if (_amount == 0 || price == 0) {
            return 0;
        }
        console2.log("We're about to revert with Arithmetic over/underflow");
        uint256 priceWithPrecision = uint256(price) * ADDITIONAL_FEED_PRECISION;
        console.log("### ~ priceWithPrecision:", priceWithPrecision);
        console.log("### ~ _amount:", _amount);
        uint256 usdValue = (priceWithPrecision * _amount) / PRECISION;
        console.log("### ~ usdValue:", usdValue);
        return usdValue;
    }

    /**
     * @dev Returns the maximum amount of DSC that can be minted by the caller.
     * @param _token The address of the token used as collateral.
     * @param _amount The amount of collateral token.
     * @return The maximum amount of DSC that can be minted.
     */
    function getMaxMintableDsc(address _token, uint256 _amount) public view returns (uint256) {
        uint256 currentCollateralInUsd = getCollateralUSDValue(msg.sender);
        uint256 collateralValueInUsd = getUSDValue(s_priceFeeds[_token], _amount);
        uint totalCollateralInUsd = currentCollateralInUsd + collateralValueInUsd;
        uint256 maxMintableDsc = totalCollateralInUsd / 2;
        
        if (maxMintableDsc < 0 || maxMintableDsc < s_usersDSC[msg.sender]) {
            return 0;
        }

        if (s_usersDSC[msg.sender] > 0){
            maxMintableDsc -= s_usersDSC[msg.sender];
        }

        return maxMintableDsc;
    }
}
