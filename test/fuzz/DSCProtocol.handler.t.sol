// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test, StdInvariant, console} from "forge-std/Test.sol";
import {DSCoin} from "../../src/DSCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {ConfigHelper} from "../../script/ConfigHelper.s.sol";
import {ERC20Mock} from "@openzeppelin/mocks/token/ERC20Mock.sol";


contract DSCProtocolHandler is StdInvariant, Test {
    DSCoin dsc;
    DSCEngine engine;
    ConfigHelper.Configuration config;
    address[] allowedCollaterals = new address[](2);
    address alice;
    uint96 constant MAX_DEPOSIT = type(uint96).max;

    constructor(address _dsc, address _engine, ConfigHelper.Configuration memory _config, address _alice) {
        dsc = DSCoin(_dsc);
        engine = DSCEngine(_engine);
        config = _config;
        allowedCollaterals[0] = _config.wETHaddress;
        allowedCollaterals[1] = _config.wBTCaddress;
        alice = _alice;
    }


    function depositCollateral(uint _collateralIndex, uint _amount) public {
        (address collateral, uint amount) = _getAllowedCollateralAndMaxAmount(_collateralIndex, _amount);
        
        vm.startPrank(alice);
        _mintAndApproveCollateral(collateral, amount);
        engine.depositCollateral(collateral, amount);
        vm.stopPrank();
    }

    function redeemCollateral(uint _collateralIndex, uint _randomizedAmount) public {
        (address collateral, uint amount) = _getAllowedCollateralAndMaxAmount(_collateralIndex, _randomizedAmount);
        
        vm.startPrank(alice);
        _mintAndApproveCollateral(collateral, amount);
        engine.depositCollateral(collateral, amount);

        uint maxCollateral = engine.getCollateralDeposit(collateral);
        amount = bound(amount, 1, maxCollateral);
        
        engine.redeemCollateral(collateral, amount);
        vm.stopPrank();
    }

    function mintDSC(uint _collateralIndex, uint _randomizedAmount) public {
        (address collateral, uint amount) = _getAllowedCollateralAndMaxAmount(_collateralIndex, _randomizedAmount);
        vm.startPrank(alice);
        _mintAndApproveCollateral(collateral, amount);
        engine.depositCollateral(collateral, amount);

        (uint totalDscMinted, uint collateralValueInUsd) = engine.getAccountInformation();
        int maxDscToMint = (int(collateralValueInUsd) / 2) - int(totalDscMinted);

        engine.mintDSC(uint(maxDscToMint));
        vm.stopPrank();
    }
    
    function _getAllowedCollateralAndMaxAmount(uint _collateralIndex, uint _amount) private view returns (address, uint) {
        uint index = bound(_collateralIndex,0, 1);
        address collateral = allowedCollaterals[index]; 
        _amount = bound(_amount, 1, type(uint96).max);
        return (collateral, _amount);
    }

    function _mintAndApproveCollateral(address _collateral, uint _amount) private {
        ERC20Mock(_collateral).mint(alice, _amount);
        ERC20Mock(_collateral).approve(address(engine), _amount);
    }
}
