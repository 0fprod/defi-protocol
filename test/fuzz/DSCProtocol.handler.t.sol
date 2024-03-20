// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test, StdInvariant, console2} from "forge-std/Test.sol";
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

    constructor(address _dsc, address _engine, ConfigHelper.Configuration memory _config, address _alice) {
        dsc = DSCoin(_dsc);
        engine = DSCEngine(_engine);
        config = _config;
        allowedCollaterals[0] = _config.wETHaddress;
        allowedCollaterals[1] = _config.wBTCaddress;
        alice = _alice;
    }

    function depositCollateral(uint _collateralIndex, uint _amount) public {
        uint index = bound(_collateralIndex,0, 1);
        address collateral = allowedCollaterals[index]; 
        _amount = bound(_amount, 1, type(uint).max);
        
        vm.startPrank(alice);
        ERC20Mock(collateral).mint(alice, _amount);
        ERC20Mock(collateral).approve(address(engine), _amount);
        engine.depositCollateral(collateral, _amount);
        vm.stopPrank();
    }
}
